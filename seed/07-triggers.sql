-- =============================================================================
-- 07-triggers.sql — wire up triggers to the functions defined in 05-*
-- =============================================================================
--
-- Two trigger families:
--   1. updated_at maintenance — bump updated_at on every UPDATE
--   2. audit logging         — write change events to audit.change_log
--   3. business-rule          — order_total recompute, journal balance check
--
-- Convention: trigger names are tg_<event>_<purpose>, e.g.
-- tg_au_employees_audit (AFTER UPDATE on employees).

\echo '== updated_at triggers =='

-- HR
CREATE TRIGGER tg_bu_departments_updated_at  BEFORE UPDATE ON hr.departments  FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_positions_updated_at    BEFORE UPDATE ON hr.positions    FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_employees_updated_at    BEFORE UPDATE ON hr.employees    FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_payroll_updated_at      BEFORE UPDATE ON hr.payroll      FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_leave_updated_at        BEFORE UPDATE ON hr.leave_requests FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();

-- Sales
CREATE TRIGGER tg_bu_products_updated_at      BEFORE UPDATE ON sales.products      FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_customers_updated_at     BEFORE UPDATE ON sales.customers     FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_contacts_updated_at      BEFORE UPDATE ON sales.contacts      FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_opps_updated_at          BEFORE UPDATE ON sales.opportunities FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_orders_updated_at        BEFORE UPDATE ON sales.orders        FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_invoices_updated_at      BEFORE UPDATE ON sales.invoices      FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();

-- Finance
CREATE TRIGGER tg_bu_periods_updated_at        BEFORE UPDATE ON finance.fiscal_periods    FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_accounts_updated_at       BEFORE UPDATE ON finance.chart_of_accounts FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_journal_entries_updated_at BEFORE UPDATE ON finance.journal_entries  FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();
CREATE TRIGGER tg_bu_budgets_updated_at        BEFORE UPDATE ON finance.budgets           FOR EACH ROW EXECUTE FUNCTION audit.tg_set_updated_at();

\echo '== audit triggers =='

-- AFTER row-level: fires after the actual row change committed.
-- We attach to the high-value tables only (audit-trigger overhead is real).

CREATE TRIGGER tg_a_employees_audit
  AFTER INSERT OR UPDATE OR DELETE ON hr.employees
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_departments_audit
  AFTER INSERT OR UPDATE OR DELETE ON hr.departments
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_payroll_audit
  AFTER INSERT OR UPDATE OR DELETE ON hr.payroll
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_customers_audit
  AFTER INSERT OR UPDATE OR DELETE ON sales.customers
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_orders_audit
  AFTER INSERT OR UPDATE OR DELETE ON sales.orders
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_invoices_audit
  AFTER INSERT OR UPDATE OR DELETE ON sales.invoices
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER tg_a_journal_entries_audit
  AFTER INSERT OR UPDATE OR DELETE ON finance.journal_entries
  FOR EACH ROW EXECUTE FUNCTION audit.log_change();

\echo '== business-rule triggers =='

-- Recompute orders.total_amount whenever an order_items row is added/changed/deleted.
CREATE TRIGGER tg_aiud_order_items_refresh_total
  AFTER INSERT OR UPDATE OR DELETE ON sales.order_items
  FOR EACH ROW EXECUTE FUNCTION sales.tg_refresh_order_total();

-- Constraint trigger for double-entry GL: deferred to COMMIT so the trigger
-- runs ONCE per entry (not per line). Lets you insert all lines in any order.
CREATE CONSTRAINT TRIGGER tg_aiud_journal_lines_balance_check
  AFTER INSERT OR UPDATE OR DELETE ON finance.journal_lines
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION finance.tg_check_journal_balance();

\echo '== triggers wired =='
