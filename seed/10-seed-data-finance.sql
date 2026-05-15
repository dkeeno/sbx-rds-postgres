-- =============================================================================
-- 10-seed-data-finance.sql — fictional GL data (chart of accounts + journals)
-- =============================================================================
--
-- 12 fiscal periods (FY2026 monthly), 30-account chart, 24 budget entries,
-- 12 posted journal entries with balanced lines.

\echo '== Seeding finance.fiscal_periods (FY2026, monthly) =='

INSERT INTO finance.fiscal_periods (period_code, fiscal_year, period_number, start_date, end_date, status) VALUES
  ('FY2026-01', 2026,  1, '2026-01-01', '2026-01-31', 'closed'),
  ('FY2026-02', 2026,  2, '2026-02-01', '2026-02-28', 'closed'),
  ('FY2026-03', 2026,  3, '2026-03-01', '2026-03-31', 'closed'),
  ('FY2026-04', 2026,  4, '2026-04-01', '2026-04-30', 'closed'),
  ('FY2026-05', 2026,  5, '2026-05-01', '2026-05-31', 'open'),
  ('FY2026-06', 2026,  6, '2026-06-01', '2026-06-30', 'open'),
  ('FY2026-07', 2026,  7, '2026-07-01', '2026-07-31', 'open'),
  ('FY2026-08', 2026,  8, '2026-08-01', '2026-08-31', 'open'),
  ('FY2026-09', 2026,  9, '2026-09-01', '2026-09-30', 'open'),
  ('FY2026-10', 2026, 10, '2026-10-01', '2026-10-31', 'open'),
  ('FY2026-11', 2026, 11, '2026-11-01', '2026-11-30', 'open'),
  ('FY2026-12', 2026, 12, '2026-12-01', '2026-12-31', 'open')
ON CONFLICT (period_code) DO NOTHING;

-- Set closed_at + closed_by for the closed periods (CFO = employee 2)
UPDATE finance.fiscal_periods SET closed_at = '2026-02-05 17:00:00+00', closed_by = 2 WHERE period_code = 'FY2026-01';
UPDATE finance.fiscal_periods SET closed_at = '2026-03-04 17:00:00+00', closed_by = 2 WHERE period_code = 'FY2026-02';
UPDATE finance.fiscal_periods SET closed_at = '2026-04-03 17:00:00+00', closed_by = 2 WHERE period_code = 'FY2026-03';
UPDATE finance.fiscal_periods SET closed_at = '2026-05-04 17:00:00+00', closed_by = 2 WHERE period_code = 'FY2026-04';

\echo '== Seeding finance.chart_of_accounts =='

INSERT INTO finance.chart_of_accounts (account_code, name, account_class, normal_balance, is_postable, parent_id) VALUES
  -- Assets
  ('1000', 'Current Assets',                'asset',     'DR', false, NULL),
  ('1010', 'Cash — Operating Account',      'asset',     'DR', true,  NULL),
  ('1020', 'Cash — Reserve Account',        'asset',     'DR', true,  NULL),
  ('1100', 'Accounts Receivable',           'asset',     'DR', true,  NULL),
  ('1200', 'Inventory — Raw Materials',     'asset',     'DR', true,  NULL),
  ('1210', 'Inventory — Finished Goods',    'asset',     'DR', true,  NULL),
  ('1500', 'Property, Plant & Equipment',   'asset',     'DR', true,  NULL),
  ('1510', 'Accumulated Depreciation',      'asset',     'CR', true,  NULL),
  -- Liabilities
  ('2000', 'Current Liabilities',           'liability', 'CR', false, NULL),
  ('2010', 'Accounts Payable',              'liability', 'CR', true,  NULL),
  ('2020', 'Accrued Payroll',               'liability', 'CR', true,  NULL),
  ('2030', 'Sales Tax Payable',             'liability', 'CR', true,  NULL),
  ('2100', 'Long-term Debt',                'liability', 'CR', true,  NULL),
  -- Equity
  ('3000', 'Common Stock',                  'equity',    'CR', true,  NULL),
  ('3010', 'Retained Earnings',             'equity',    'CR', true,  NULL),
  -- Revenue
  ('4000', 'Product Revenue — Industrial',  'revenue',   'CR', true,  NULL),
  ('4010', 'Product Revenue — Consumer',    'revenue',   'CR', true,  NULL),
  ('4020', 'Service Revenue',               'revenue',   'CR', true,  NULL),
  -- Expenses (5xxx COGS, 6xxx OpEx, 7xxx Compensation, 8xxx Other)
  ('5000', 'COGS — Raw Materials',          'expense',   'DR', true,  NULL),
  ('5010', 'COGS — Manufacturing Overhead', 'expense',   'DR', true,  NULL),
  ('6000', 'Rent Expense',                  'expense',   'DR', true,  NULL),
  ('6010', 'Utilities Expense',             'expense',   'DR', true,  NULL),
  ('6020', 'Software & Subscriptions',      'expense',   'DR', true,  NULL),
  ('6030', 'Marketing Expense',             'expense',   'DR', true,  NULL),
  ('6040', 'Travel Expense',                'expense',   'DR', true,  NULL),
  ('6050', 'Professional Services',         'expense',   'DR', true,  NULL),
  ('7000', 'Salaries & Wages',              'expense',   'DR', true,  NULL),
  ('7010', 'Payroll Taxes',                 'expense',   'DR', true,  NULL),
  ('7020', 'Pension Contributions',         'expense',   'DR', true,  NULL),
  ('8000', 'Depreciation Expense',          'expense',   'DR', true,  NULL)
ON CONFLICT (account_code) DO NOTHING;

\echo '== Seeding finance.budgets (annual budget per account, monthly) =='

-- Generate 12-month flat budget for the major OpEx + Revenue accounts.
-- Real companies vary by month; flat is fine for the demo.
INSERT INTO finance.budgets (account_id, fiscal_year, month_no, amount, notes)
SELECT
  a.id,
  2026,
  m,
  CASE a.account_code
    WHEN '4000' THEN  650000.00  -- monthly industrial revenue target
    WHEN '4010' THEN  180000.00
    WHEN '4020' THEN  220000.00
    WHEN '5000' THEN -260000.00
    WHEN '5010' THEN  -95000.00
    WHEN '6000' THEN  -45000.00
    WHEN '6020' THEN  -28000.00
    WHEN '6030' THEN  -55000.00
    WHEN '7000' THEN -480000.00
    WHEN '7010' THEN -106000.00
    WHEN '7020' THEN  -24000.00
  END,
  'Opening budget — committed Dec 2025'
FROM finance.chart_of_accounts a
CROSS JOIN generate_series(1, 12) AS m
WHERE a.account_code IN ('4000','4010','4020','5000','5010','6000','6020','6030','7000','7010','7020')
ON CONFLICT (account_id, fiscal_year, month_no, revision) DO NOTHING;

\echo '== Seeding finance.journal_entries + journal_lines (12 entries) =='

-- Helper: lookup wrappers so we don't repeat the SELECT pattern. Inline below.
-- Each journal must balance (sum debits = sum credits) — enforced by constraint trigger.

-- JE 1 — January revenue from invoice INV-2026-00003 (LIH, $28,242)
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000001', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-01'), '2026-01-20', 'AR + Revenue from LIH order',         'invoice', 'INV-2026-00003', true, '2026-01-21 09:00:00+00', 8, 65);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (1, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1100'), 28241.90,     0, 'AR — LIH'),
  (1, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='4000'),        0, 25910.00, 'Industrial revenue'),
  (1, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2030'),        0,  2331.90, 'Sales tax 9% accrued');

-- JE 2 — January cash collection from a prior-period invoice
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000002', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-01'), '2026-01-28', 'Cash collected from prior-year AR',     'manual',  '',                true, '2026-01-29 10:30:00+00', 8, 65);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (2, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1010'), 95000.00,     0, 'Cash deposit'),
  (2, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1100'),        0, 95000.00, 'AR cleared');

-- JE 3 — February rent + utilities (monthly recurring)
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000003', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-02'), '2026-02-01', 'Monthly rent + utilities accrual',      'accrual', '',                true, '2026-02-01 12:00:00+00', 8, 64);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (3, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6000'), 42000.00,     0, 'Rent — HQ'),
  (3, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6010'),  6800.00,     0, 'Electricity + water'),
  (3, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2010'),        0, 48800.00, 'Landlord + utility AP');

-- JE 4 — February revenue from RJSW invoice
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000004', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-02'), '2026-02-14', 'AR + Revenue from RJSW',                'invoice', 'INV-2026-00006', true, '2026-02-15 09:30:00+00', 8, 65);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (4, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1100'), 61476.00,     0, 'AR — RJSW'),
  (4, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='4000'),        0, 50000.00, 'Industrial revenue'),
  (4, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='4020'),        0,  6400.00, 'Service revenue'),
  (4, 4, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2030'),        0,  5076.00, 'Sales tax');

-- JE 5 — February payroll
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000005', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-02'), '2026-02-28', 'February payroll run',                  'payroll', 'PR-202602',      true, '2026-02-28 17:00:00+00', 8, 63);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (5, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='7000'), 482000.00,    0, 'Gross salaries'),
  (5, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='7010'), 106040.00,    0, 'Employer payroll taxes'),
  (5, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='7020'),  24100.00,    0, 'Pension contributions'),
  (5, 4, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2020'),         0, 612140.00, 'Accrued payroll liability');

-- JE 6 — March marketing campaign
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000006', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-03'), '2026-03-12', 'Q1 marketing campaign — trade show',    'manual',  '',                true, '2026-03-13 10:00:00+00', 8, 64);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (6, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6030'), 38000.00,     0, 'Trade show booth + collateral'),
  (6, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2010'),        0, 38000.00, 'AP to vendor');

-- JE 7 — March software renewals
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000007', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-03'), '2026-03-15', 'Annual ERP + design software renewals', 'manual',  '',                true, '2026-03-16 11:00:00+00', 8, 65);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (7, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6020'), 28500.00,     0, 'ERP annual + AutoCAD seats'),
  (7, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1010'),        0, 28500.00, 'Cash payment');

-- JE 8 — March COGS for delivered orders
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000008', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-03'), '2026-03-31', 'COGS recognition for March deliveries', 'accrual', '',                true, '2026-04-01 09:00:00+00', 8, 64);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (8, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='5000'), 178000.00,    0, 'Materials consumed'),
  (8, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='5010'),  62000.00,    0, 'Manufacturing overhead'),
  (8, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1200'),         0,178000.00, 'Inventory drawdown — raw'),
  (8, 4, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1210'),         0, 62000.00, 'Inventory drawdown — finished');

-- JE 9 — March depreciation
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000009', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-03'), '2026-03-31', 'Monthly straight-line depreciation',    'accrual', '',                true, '2026-04-01 09:30:00+00', 8, 64);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (9, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='8000'),  18500.00,    0, 'Monthly depreciation'),
  (9, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1510'),         0, 18500.00, 'Acc. depreciation');

-- JE 10 — April Atlas Foods invoice
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000010', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-04'), '2026-04-02', 'AR + Revenue from Atlas Foods',         'invoice', 'INV-2026-00005', true, '2026-04-02 13:00:00+00', 8, 67);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (10, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='1100'), 12644.00,    0, 'AR — Atlas'),
  (10, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='4020'),        0, 11600.00, 'Service revenue'),
  (10, 3, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2030'),        0,  1044.00, 'Sales tax');

-- JE 11 — April travel & expenses
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000011', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-04'), '2026-04-22', 'Sales team travel — Q1 customer visits','manual',  'EXP-Q1-TRAVEL',   true, '2026-04-23 11:30:00+00', 8, 67);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (11, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6040'),  22400.00,   0, 'Air + hotel + meals'),
  (11, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2010'),         0, 22400.00, 'AP — corporate card');

-- JE 12 — May (open period) DRAFT entry — not posted
INSERT INTO finance.journal_entries (entry_number, period_id, entry_date, description, source_type, source_ref, posted, posted_at, posted_by, created_by) VALUES
  ('JE-2026-000012', (SELECT id FROM finance.fiscal_periods WHERE period_code='FY2026-05'), '2026-05-10', 'Professional services — auditors',      'manual',  '',                false, NULL,                    NULL, 64);
INSERT INTO finance.journal_lines (entry_id, line_no, account_id, debit, credit, memo) VALUES
  (12, 1, (SELECT id FROM finance.chart_of_accounts WHERE account_code='6050'),  18500.00,   0, 'Q1 audit fees'),
  (12, 2, (SELECT id FROM finance.chart_of_accounts WHERE account_code='2010'),         0, 18500.00, 'AP — auditor');

\echo '== Finance seed: 12 periods, 30 accounts, 132 budget rows, 12 journals (~30 lines), all balanced =='
