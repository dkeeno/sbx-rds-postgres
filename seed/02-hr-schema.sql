-- =============================================================================
-- 02-hr-schema.sql — HR tables (departments, positions, employees, payroll, leave)
-- =============================================================================
--
-- Domain: a fictional manufacturing company "Helix Atlas Industrial Ltd".
-- Tables are normalized (3NF) — departments → positions → employees, with
-- payroll + leave_requests as child tables of employees.
--
-- Conventions:
--   - Surrogate PKs are bigserial (sequential bigint). Natural keys (codes,
--     emails) get unique constraints alongside.
--   - All timestamps are TIMESTAMPTZ in UTC. created_at / updated_at on
--     every table; updated_at maintained by trigger (07-triggers.sql).
--   - Soft deletes on employees only (deleted_at). Other tables hard-delete.
--
-- Order: depends on schemas + roles from 01-*. Must run before triggers
-- (07-*) and seed data (08-*).

\echo '== Building hr.* tables =='

-- ----------- departments ---------------------------------------------------
CREATE TABLE IF NOT EXISTS hr.departments (
  id              BIGSERIAL    PRIMARY KEY,
  code            TEXT         NOT NULL UNIQUE CHECK (code = upper(code) AND length(code) BETWEEN 2 AND 6),
  name            TEXT         NOT NULL,
  cost_center     TEXT         NOT NULL,
  parent_id       BIGINT       REFERENCES hr.departments(id) ON DELETE SET NULL,  -- self-referencing for org hierarchy
  manager_id      BIGINT,                                                          -- FK added later (after employees exists)
  budget_annual   NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (budget_annual >= 0),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
COMMENT ON TABLE  hr.departments        IS 'Org units. Hierarchical via parent_id. manager_id FK to employees added in 08-seed-data.';
COMMENT ON COLUMN hr.departments.code   IS 'Short uppercase identifier (e.g. ENG, FIN, OPS).';

-- ----------- positions (job titles + salary bands) ------------------------
CREATE TABLE IF NOT EXISTS hr.positions (
  id              BIGSERIAL    PRIMARY KEY,
  title           TEXT         NOT NULL,
  job_family      TEXT         NOT NULL,                  -- e.g. 'Engineering', 'Operations'
  level           SMALLINT     NOT NULL CHECK (level BETWEEN 1 AND 10),
  -- Salary bands per position. ranges use the numrange type so we can
  -- detect band overlaps with EXCLUDE constraints on per-family ranges
  -- (out-of-scope here but the data type supports it).
  salary_min      NUMERIC(10,2) NOT NULL CHECK (salary_min >= 0),
  salary_max      NUMERIC(10,2) NOT NULL CHECK (salary_max >= salary_min),
  is_management   BOOLEAN      NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_positions_family_level ON hr.positions (job_family, level);
COMMENT ON TABLE hr.positions IS 'Catalog of job titles + salary bands. Employees reference one position.';

-- ----------- employees -----------------------------------------------------
CREATE TABLE IF NOT EXISTS hr.employees (
  id              BIGSERIAL    PRIMARY KEY,
  employee_number TEXT         NOT NULL UNIQUE,           -- e.g. 'E000123'
  first_name      TEXT         NOT NULL,
  last_name       TEXT         NOT NULL,
  email           CITEXT       NOT NULL UNIQUE,           -- case-insensitive comparison
  phone           TEXT,
  date_of_birth   DATE,
  hired_at        DATE         NOT NULL,
  terminated_at   DATE         CHECK (terminated_at IS NULL OR terminated_at >= hired_at),
  department_id   BIGINT       NOT NULL REFERENCES hr.departments(id),
  position_id     BIGINT       NOT NULL REFERENCES hr.positions(id),
  manager_id      BIGINT       REFERENCES hr.employees(id) ON DELETE SET NULL,    -- self-FK
  base_salary     NUMERIC(10,2) NOT NULL CHECK (base_salary >= 0),
  -- Generated column: full_name auto-derived. STORED so it lives on disk
  -- (slight space cost, free reads) and can be indexed.
  full_name       TEXT         GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  -- Demographic + emergency contact stored as JSONB for schema flexibility.
  metadata        JSONB        NOT NULL DEFAULT '{}'::jsonb,
  -- Soft-delete marker. NULL = active; set to a timestamp on offboarding.
  deleted_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_employees_dept     ON hr.employees (department_id);
CREATE INDEX IF NOT EXISTS idx_employees_manager  ON hr.employees (manager_id);
CREATE INDEX IF NOT EXISTS idx_employees_active   ON hr.employees (department_id) WHERE deleted_at IS NULL AND terminated_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_employees_metadata ON hr.employees USING gin (metadata);
COMMENT ON TABLE hr.employees IS 'All people who have ever been employed. Use the v_active_employees view for current roster.';

-- Now we can backfill the FK from departments.manager_id → employees.id
-- (must come AFTER employees exists; data populated in 08-*).
ALTER TABLE hr.departments
  ADD CONSTRAINT departments_manager_fkey
  FOREIGN KEY (manager_id) REFERENCES hr.employees(id) ON DELETE SET NULL;

-- ----------- payroll -------------------------------------------------------
CREATE TABLE IF NOT EXISTS hr.payroll (
  id              BIGSERIAL    PRIMARY KEY,
  employee_id     BIGINT       NOT NULL REFERENCES hr.employees(id) ON DELETE CASCADE,
  pay_period      DATERANGE    NOT NULL,                  -- e.g. [2026-04-01, 2026-05-01)
  gross_pay       NUMERIC(10,2) NOT NULL CHECK (gross_pay >= 0),
  taxes           NUMERIC(10,2) NOT NULL CHECK (taxes >= 0),
  pension         NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (pension >= 0),
  other_deductions NUMERIC(10,2) NOT NULL DEFAULT 0,
  net_pay         NUMERIC(10,2) GENERATED ALWAYS AS (gross_pay - taxes - pension - other_deductions) STORED,
  paid_at         DATE,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  -- One payroll record per employee per period — exclude overlapping ranges.
  EXCLUDE USING gist (employee_id WITH =, pay_period WITH &&)
);
CREATE INDEX IF NOT EXISTS idx_payroll_employee ON hr.payroll (employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_period   ON hr.payroll USING gist (pay_period);
COMMENT ON TABLE hr.payroll IS 'Per-employee per-period payroll record. Periods are non-overlapping (EXCLUDE constraint).';

-- ----------- leave_requests -----------------------------------------------
CREATE TABLE IF NOT EXISTS hr.leave_requests (
  id              BIGSERIAL    PRIMARY KEY,
  employee_id     BIGINT       NOT NULL REFERENCES hr.employees(id) ON DELETE CASCADE,
  leave_type      TEXT         NOT NULL CHECK (leave_type IN ('annual','sick','parental','unpaid','jury','bereavement')),
  period          DATERANGE    NOT NULL,                  -- inclusive lower, exclusive upper
  status          TEXT         NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','cancelled')),
  approver_id     BIGINT       REFERENCES hr.employees(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_leave_employee_status ON hr.leave_requests (employee_id, status);
CREATE INDEX IF NOT EXISTS idx_leave_period          ON hr.leave_requests USING gist (period);
COMMENT ON TABLE hr.leave_requests IS 'Time-off requests with approval workflow.';

\echo '== hr.* tables ready =='
