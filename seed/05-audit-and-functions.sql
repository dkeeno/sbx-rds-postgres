-- =============================================================================
-- 05-audit-and-functions.sql — audit log + reusable business functions
-- =============================================================================
--
-- Audit pattern: a single change_log table catches all INSERT/UPDATE/DELETE
-- across hr/sales/finance via a row-level trigger function. The trigger
-- writes a JSONB diff (old_data/new_data) and the IP/role/session info.
--
-- Functions in this file:
--   audit.log_change()                  — universal audit trigger function
--   audit.tg_set_updated_at()           — bumps updated_at on row update
--   hr.calculate_tenure_years(emp_id)   — returns years between hired_at and today
--   hr.fn_employee_full_record(emp_id)  — returns a JSONB blob with all employee + dept + position info
--   sales.calc_order_total(order_id)    — returns sum of line totals
--   finance.fiscal_period_for_date(d)   — looks up period_id for any calendar date
--   finance.tg_check_journal_balance()  — constraint trigger enforcing debits=credits

\echo '== Audit log table =='

CREATE TABLE IF NOT EXISTS audit.change_log (
  id              BIGSERIAL    PRIMARY KEY,
  changed_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  schema_name     TEXT         NOT NULL,
  table_name      TEXT         NOT NULL,
  operation       CHAR(1)      NOT NULL CHECK (operation IN ('I','U','D')),
  primary_key_id  BIGINT,                                                -- best-effort: the row's id column
  old_data        JSONB,                                                 -- NULL on INSERT
  new_data        JSONB,                                                 -- NULL on DELETE
  -- Session context
  changed_by_user TEXT         NOT NULL DEFAULT current_user,
  client_addr     INET         DEFAULT inet_client_addr(),
  application_name TEXT        DEFAULT current_setting('application_name', true)
);
CREATE INDEX IF NOT EXISTS idx_change_log_table_time ON audit.change_log (schema_name, table_name, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_change_log_pk         ON audit.change_log (primary_key_id) WHERE primary_key_id IS NOT NULL;
COMMENT ON TABLE audit.change_log IS 'Append-only audit log written by the audit.log_change() trigger function.';

-- audit.change_log is INSERT-only — revoke direct DML for safety.
REVOKE INSERT, UPDATE, DELETE ON audit.change_log FROM PUBLIC;
GRANT  INSERT ON audit.change_log TO app_readwrite;
-- Triggers run as the table owner (dbadmin), so no special grant needed for them.

\echo '== Function: audit.log_change() — universal audit trigger =='

CREATE OR REPLACE FUNCTION audit.log_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER  -- runs as table owner (dbadmin), can write to audit.change_log even when caller can't
AS $$
DECLARE
  pk BIGINT;
BEGIN
  -- Best-effort PK extraction from NEW or OLD by looking at the 'id' column.
  -- Tables without a numeric `id` (e.g. composite-PK ones) just store NULL.
  IF (TG_OP = 'DELETE') THEN
    BEGIN
      pk := (to_jsonb(OLD) ->> 'id')::BIGINT;
    EXCEPTION WHEN OTHERS THEN
      pk := NULL;
    END;

    INSERT INTO audit.change_log (schema_name, table_name, operation, primary_key_id, old_data)
    VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 'D', pk, to_jsonb(OLD));
    RETURN OLD;

  ELSIF (TG_OP = 'UPDATE') THEN
    BEGIN
      pk := (to_jsonb(NEW) ->> 'id')::BIGINT;
    EXCEPTION WHEN OTHERS THEN
      pk := NULL;
    END;

    -- Skip no-op updates (e.g. a row UPDATE that didn't change any column).
    IF (to_jsonb(OLD) = to_jsonb(NEW)) THEN
      RETURN NEW;
    END IF;

    INSERT INTO audit.change_log (schema_name, table_name, operation, primary_key_id, old_data, new_data)
    VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 'U', pk, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;

  ELSIF (TG_OP = 'INSERT') THEN
    BEGIN
      pk := (to_jsonb(NEW) ->> 'id')::BIGINT;
    EXCEPTION WHEN OTHERS THEN
      pk := NULL;
    END;

    INSERT INTO audit.change_log (schema_name, table_name, operation, primary_key_id, new_data)
    VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 'I', pk, to_jsonb(NEW));
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$;
COMMENT ON FUNCTION audit.log_change() IS 'Universal AFTER row trigger — writes I/U/D events to audit.change_log.';

\echo '== Function: audit.tg_set_updated_at() — keeps updated_at fresh =='

CREATE OR REPLACE FUNCTION audit.tg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
COMMENT ON FUNCTION audit.tg_set_updated_at() IS 'BEFORE UPDATE row trigger that bumps updated_at to now().';

\echo '== Function: hr.calculate_tenure_years(employee_id) =='

CREATE OR REPLACE FUNCTION hr.calculate_tenure_years(p_employee_id BIGINT)
RETURNS NUMERIC
LANGUAGE sql
STABLE  -- no side effects, same input → same output within a transaction
AS $$
  SELECT
    EXTRACT(EPOCH FROM (
      COALESCE(terminated_at, CURRENT_DATE)::timestamptz - hired_at::timestamptz
    )) / (60 * 60 * 24 * 365.25)
  FROM hr.employees
  WHERE id = p_employee_id;
$$;
COMMENT ON FUNCTION hr.calculate_tenure_years(BIGINT) IS
  'Returns years (NUMERIC) between hired_at and terminated_at (or today if active).';

\echo '== Function: hr.fn_employee_full_record(employee_id) =='

CREATE OR REPLACE FUNCTION hr.fn_employee_full_record(p_employee_id BIGINT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT jsonb_build_object(
    'employee', to_jsonb(e),
    'department', to_jsonb(d),
    'position',   to_jsonb(p),
    'manager',    (SELECT jsonb_build_object('id', m.id, 'name', m.full_name)
                   FROM hr.employees m WHERE m.id = e.manager_id),
    'tenure_years', hr.calculate_tenure_years(e.id)
  )
  FROM hr.employees e
  JOIN hr.departments d ON d.id = e.department_id
  JOIN hr.positions   p ON p.id = e.position_id
  WHERE e.id = p_employee_id;
$$;
COMMENT ON FUNCTION hr.fn_employee_full_record(BIGINT) IS
  'Returns a JSONB blob with employee + dept + position + manager summary.';

\echo '== Function: sales.calc_order_total(order_id) =='

CREATE OR REPLACE FUNCTION sales.calc_order_total(p_order_id BIGINT)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(line_total), 0)::NUMERIC(12,2)
  FROM sales.order_items
  WHERE order_id = p_order_id;
$$;
COMMENT ON FUNCTION sales.calc_order_total(BIGINT) IS
  'Sum of line_total across order_items for one order.';

\echo '== Function: sales.tg_refresh_order_total() — keeps orders.total_amount accurate =='

CREATE OR REPLACE FUNCTION sales.tg_refresh_order_total()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id BIGINT;
BEGIN
  v_order_id := COALESCE(NEW.order_id, OLD.order_id);
  UPDATE sales.orders
     SET total_amount = sales.calc_order_total(v_order_id),
         updated_at   = now()
   WHERE id = v_order_id;
  RETURN COALESCE(NEW, OLD);
END;
$$;

\echo '== Function: finance.fiscal_period_for_date(d) =='

CREATE OR REPLACE FUNCTION finance.fiscal_period_for_date(p_date DATE)
RETURNS BIGINT
LANGUAGE sql
STABLE
AS $$
  SELECT id
  FROM finance.fiscal_periods
  WHERE p_date BETWEEN start_date AND end_date
  ORDER BY start_date DESC
  LIMIT 1;
$$;
COMMENT ON FUNCTION finance.fiscal_period_for_date(DATE) IS
  'Look up the fiscal_period_id whose [start_date, end_date] window contains the given date.';

\echo '== Function: finance.tg_check_journal_balance() — debits = credits =='

CREATE OR REPLACE FUNCTION finance.tg_check_journal_balance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_diff NUMERIC;
BEGIN
  -- Sum debits - credits across all lines of the entry.
  SELECT COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0)
    INTO v_diff
    FROM finance.journal_lines
   WHERE entry_id = COALESCE(NEW.entry_id, OLD.entry_id);

  IF v_diff <> 0 THEN
    RAISE EXCEPTION
      'Journal entry % is unbalanced: debits - credits = %',
      COALESCE(NEW.entry_id, OLD.entry_id), v_diff
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NULL;  -- AFTER trigger; return value ignored
END;
$$;
COMMENT ON FUNCTION finance.tg_check_journal_balance() IS
  'CONSTRAINT TRIGGER deferred to commit: rejects journal_entries whose lines do not balance.';

\echo '== audit log + functions ready =='
