-- =============================================================================
-- 04-finance-schema.sql — General Ledger + budgets
-- =============================================================================
--
-- A simplified double-entry GL: every journal_entry has 2+ journal_lines
-- whose debits and credits must sum to zero (enforced by a CHECK trigger
-- in 07-triggers.sql, since CHECK constraints can't span rows).
--
-- chart_of_accounts is hierarchical (5-class root: Asset, Liability,
-- Equity, Revenue, Expense). Account codes follow standard accounting
-- conventions (1xxx Asset, 2xxx Liability, 3xxx Equity, 4xxx Revenue,
-- 5xxx-9xxx Expense).

\echo '== Building finance.* tables =='

-- ----------- fiscal_periods ------------------------------------------------
-- Monthly periods. status flips to 'closed' after month-end → no further
-- journals can target a closed period (enforced by trigger in 07-*).
CREATE TABLE IF NOT EXISTS finance.fiscal_periods (
  id              BIGSERIAL    PRIMARY KEY,
  period_code     TEXT         NOT NULL UNIQUE,                          -- 'FY2026-04'
  fiscal_year     INTEGER      NOT NULL CHECK (fiscal_year BETWEEN 2000 AND 2100),
  period_number   SMALLINT     NOT NULL CHECK (period_number BETWEEN 1 AND 12),
  start_date      DATE         NOT NULL,
  end_date        DATE         NOT NULL CHECK (end_date >= start_date),
  status          TEXT         NOT NULL DEFAULT 'open' CHECK (status IN ('open','closing','closed')),
  closed_at       TIMESTAMPTZ,
  closed_by       BIGINT       REFERENCES hr.employees(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (fiscal_year, period_number)
);
CREATE INDEX IF NOT EXISTS idx_periods_dates ON finance.fiscal_periods (start_date, end_date);

-- ----------- chart_of_accounts --------------------------------------------
CREATE TABLE IF NOT EXISTS finance.chart_of_accounts (
  id              BIGSERIAL    PRIMARY KEY,
  account_code    TEXT         NOT NULL UNIQUE CHECK (account_code ~ '^[0-9]{4}$'),
  name            TEXT         NOT NULL,
  -- Account class derives from the leading digit. Encoded redundantly for
  -- query simplicity (and validated by check constraint).
  account_class   TEXT         NOT NULL CHECK (account_class IN ('asset','liability','equity','revenue','expense')),
  parent_id       BIGINT       REFERENCES finance.chart_of_accounts(id) ON DELETE RESTRICT,
  is_postable     BOOLEAN      NOT NULL DEFAULT true,                    -- false for "summary" accounts
  -- Sign convention: assets+expenses normal-debit (+); the others normal-credit (-).
  -- Tracked here so reports know which sign to show as positive.
  normal_balance  CHAR(2)      NOT NULL CHECK (normal_balance IN ('DR','CR')),
  is_active       BOOLEAN      NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  -- Class must agree with the leading-digit convention.
  CHECK (
    (left(account_code, 1) = '1' AND account_class = 'asset')     OR
    (left(account_code, 1) = '2' AND account_class = 'liability') OR
    (left(account_code, 1) = '3' AND account_class = 'equity')    OR
    (left(account_code, 1) = '4' AND account_class = 'revenue')   OR
    (left(account_code, 1) IN ('5','6','7','8','9') AND account_class = 'expense')
  )
);
CREATE INDEX IF NOT EXISTS idx_accounts_class ON finance.chart_of_accounts (account_class) WHERE is_active = true;

-- ----------- journal_entries (header) -------------------------------------
CREATE TABLE IF NOT EXISTS finance.journal_entries (
  id              BIGSERIAL    PRIMARY KEY,
  entry_number    TEXT         NOT NULL UNIQUE,                          -- 'JE-2026-000123'
  period_id       BIGINT       NOT NULL REFERENCES finance.fiscal_periods(id),
  entry_date      DATE         NOT NULL,
  description     TEXT         NOT NULL,
  source_type     TEXT         NOT NULL CHECK (source_type IN ('manual','invoice','payroll','accrual','adjustment')),
  source_ref      TEXT,                                                  -- e.g. 'INV-2026-00001'
  posted          BOOLEAN      NOT NULL DEFAULT false,
  posted_at       TIMESTAMPTZ,
  posted_by       BIGINT       REFERENCES hr.employees(id),
  created_by      BIGINT       NOT NULL REFERENCES hr.employees(id),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_journals_period_posted ON finance.journal_entries (period_id, posted);
CREATE INDEX IF NOT EXISTS idx_journals_date          ON finance.journal_entries (entry_date);

-- ----------- journal_lines (detail) ---------------------------------------
-- Double-entry bookkeeping: per entry, sum(debit) - sum(credit) MUST = 0.
-- Enforced by a CONSTRAINT TRIGGER in 07-triggers.sql.
CREATE TABLE IF NOT EXISTS finance.journal_lines (
  id              BIGSERIAL    PRIMARY KEY,
  entry_id        BIGINT       NOT NULL REFERENCES finance.journal_entries(id) ON DELETE CASCADE,
  line_no         SMALLINT     NOT NULL CHECK (line_no >= 1),
  account_id      BIGINT       NOT NULL REFERENCES finance.chart_of_accounts(id),
  -- Either debit or credit > 0; never both. Other side = 0.
  debit           NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (debit  >= 0),
  credit          NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
  CHECK ( (debit > 0 AND credit = 0) OR (debit = 0 AND credit > 0) ),
  memo            TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (entry_id, line_no)
);
CREATE INDEX IF NOT EXISTS idx_lines_account_entry ON finance.journal_lines (account_id, entry_id);

-- ----------- budgets -------------------------------------------------------
-- One row per (account, fiscal_year, month). Used for budget-vs-actual.
CREATE TABLE IF NOT EXISTS finance.budgets (
  id              BIGSERIAL    PRIMARY KEY,
  account_id      BIGINT       NOT NULL REFERENCES finance.chart_of_accounts(id),
  fiscal_year     INTEGER      NOT NULL,
  month_no        SMALLINT     NOT NULL CHECK (month_no BETWEEN 1 AND 12),
  amount          NUMERIC(14,2) NOT NULL,
  -- 'opening' is the originally approved budget. Subsequent re-forecasts
  -- create new revision rows.
  revision        SMALLINT     NOT NULL DEFAULT 1,
  notes           TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (account_id, fiscal_year, month_no, revision)
);
CREATE INDEX IF NOT EXISTS idx_budgets_year_account ON finance.budgets (fiscal_year, account_id);

\echo '== finance.* tables ready =='
