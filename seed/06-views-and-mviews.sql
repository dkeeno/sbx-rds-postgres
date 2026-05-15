-- =============================================================================
-- 06-views-and-mviews.sql — views + materialized views
-- =============================================================================
--
-- Views are the read-side API for analytics tools. Materialized views
-- (mv_*) cache expensive aggregations; refresh manually or via a cron
-- job when the underlying data changes.
--
-- Naming:
--   v_*    plain view (always fresh)
--   mv_*   materialized view (cached; needs REFRESH MATERIALIZED VIEW)

\echo '== Views =='

-- HR: employees currently on the payroll
CREATE OR REPLACE VIEW hr.v_active_employees AS
SELECT
  e.id,
  e.employee_number,
  e.full_name,
  e.email,
  d.code      AS department_code,
  d.name      AS department_name,
  p.title     AS position_title,
  p.job_family,
  e.hired_at,
  hr.calculate_tenure_years(e.id) AS tenure_years,
  e.base_salary
FROM hr.employees e
JOIN hr.departments d ON d.id = e.department_id
JOIN hr.positions   p ON p.id = e.position_id
WHERE e.deleted_at IS NULL
  AND e.terminated_at IS NULL;
COMMENT ON VIEW hr.v_active_employees IS 'Currently-employed people, joined to dept + position.';

-- Sales: open invoices (sent, not yet paid in full, not void)
CREATE OR REPLACE VIEW sales.v_open_invoices AS
SELECT
  i.id,
  i.invoice_number,
  i.issued_at,
  i.due_at,
  CASE WHEN i.due_at < CURRENT_DATE AND i.status <> 'paid' THEN true ELSE false END AS is_overdue,
  CURRENT_DATE - i.due_at AS days_overdue,
  i.total_amount,
  i.paid_amount,
  i.total_amount - i.paid_amount AS outstanding_amount,
  c.legal_name AS customer,
  c.segment,
  c.country_code,
  i.status
FROM sales.invoices i
JOIN sales.orders   o ON o.id = i.order_id
JOIN sales.customers c ON c.id = o.customer_id
WHERE i.status IN ('sent','overdue');
COMMENT ON VIEW sales.v_open_invoices IS 'Invoices awaiting full payment, with overdue calculation.';

-- Sales: pipeline summary by sales rep
CREATE OR REPLACE VIEW sales.v_pipeline_by_rep AS
SELECT
  emp.id   AS sales_rep_id,
  emp.full_name AS sales_rep,
  COUNT(*) FILTER (WHERE op.stage NOT IN ('won','lost')) AS open_opportunities,
  SUM(op.amount) FILTER (WHERE op.stage NOT IN ('won','lost')) AS pipeline_value,
  SUM(op.amount * op.probability_pct / 100.0) FILTER (WHERE op.stage NOT IN ('won','lost')) AS weighted_pipeline,
  SUM(op.amount) FILTER (WHERE op.stage = 'won' AND op.actual_close >= CURRENT_DATE - INTERVAL '90 days') AS won_last_90d
FROM hr.employees emp
LEFT JOIN sales.opportunities op ON op.owner_id = emp.id
WHERE emp.deleted_at IS NULL
GROUP BY emp.id, emp.full_name
HAVING COUNT(op.id) > 0;
COMMENT ON VIEW sales.v_pipeline_by_rep IS 'Pipeline metrics per sales rep.';

-- Finance: account balance — debits and credits summed, signed by normal_balance
CREATE OR REPLACE VIEW finance.v_account_balances AS
SELECT
  a.id          AS account_id,
  a.account_code,
  a.name        AS account_name,
  a.account_class,
  a.normal_balance,
  COALESCE(SUM(jl.debit),  0) AS total_debits,
  COALESCE(SUM(jl.credit), 0) AS total_credits,
  CASE
    WHEN a.normal_balance = 'DR' THEN COALESCE(SUM(jl.debit),  0) - COALESCE(SUM(jl.credit), 0)
    ELSE                              COALESCE(SUM(jl.credit), 0) - COALESCE(SUM(jl.debit),  0)
  END AS balance
FROM finance.chart_of_accounts a
LEFT JOIN finance.journal_lines jl ON jl.account_id = a.id
LEFT JOIN finance.journal_entries je ON je.id = jl.entry_id AND je.posted = true
WHERE a.is_active = true
GROUP BY a.id;
COMMENT ON VIEW finance.v_account_balances IS 'Posted journal balances per account, signed by normal_balance.';

\echo '== Materialized views =='

-- Monthly revenue by product category — refresh weekly or after big imports.
-- Indexed materialized views support REFRESH CONCURRENTLY.
CREATE MATERIALIZED VIEW IF NOT EXISTS sales.mv_monthly_revenue_by_category AS
SELECT
  date_trunc('month', o.ordered_at)::date AS month,
  p.category,
  COUNT(DISTINCT o.id)         AS order_count,
  SUM(oi.line_total)::NUMERIC(14,2) AS revenue,
  AVG(oi.line_total)::NUMERIC(12,2) AS avg_line_value
FROM sales.orders o
JOIN sales.order_items oi ON oi.order_id = o.id
JOIN sales.products    p  ON p.id = oi.product_id
WHERE o.status NOT IN ('cancelled')
GROUP BY date_trunc('month', o.ordered_at), p.category;

-- Unique index needed for REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_revenue_unique
  ON sales.mv_monthly_revenue_by_category (month, category);

COMMENT ON MATERIALIZED VIEW sales.mv_monthly_revenue_by_category IS
  'Monthly revenue + order count grouped by product category. Refresh: REFRESH MATERIALIZED VIEW CONCURRENTLY sales.mv_monthly_revenue_by_category;';

-- Top customers (lifetime value) — refresh nightly.
CREATE MATERIALIZED VIEW IF NOT EXISTS sales.mv_customer_lifetime_value AS
SELECT
  c.id           AS customer_id,
  c.account_number,
  c.legal_name,
  c.segment,
  c.country_code,
  COUNT(DISTINCT o.id)       AS order_count,
  COALESCE(SUM(oi.line_total), 0)::NUMERIC(14,2) AS lifetime_revenue,
  MAX(o.ordered_at)          AS last_order_at,
  -- Recency: days since last order (NULL = never ordered)
  CURRENT_DATE - MAX(o.ordered_at)::date AS days_since_last_order
FROM sales.customers c
LEFT JOIN sales.orders     o  ON o.customer_id = c.id AND o.status NOT IN ('cancelled')
LEFT JOIN sales.order_items oi ON oi.order_id   = o.id
GROUP BY c.id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_customer_ltv_unique
  ON sales.mv_customer_lifetime_value (customer_id);

COMMENT ON MATERIALIZED VIEW sales.mv_customer_lifetime_value IS
  'Per-customer order count + lifetime revenue + recency. Refresh: REFRESH MATERIALIZED VIEW CONCURRENTLY sales.mv_customer_lifetime_value;';

\echo '== views + materialized views ready =='
