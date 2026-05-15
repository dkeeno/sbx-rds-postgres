-- =============================================================================
-- 01-schemas-and-roles.sql — top-level structural setup
-- =============================================================================
--
-- WHAT: Creates the four schemas (hr, sales, finance, audit) and three
--       reusable roles (app_readonly, app_readwrite, analytics_reader).
--       Future tables/functions/views are owned BY their respective schema
--       and granted TO the relevant role.
--
-- ORDER: Run FIRST. All later seed files reference these schemas + roles.
--
-- IDEMPOTENCY: Uses IF NOT EXISTS / DROP IF EXISTS so re-runs are safe.
--
-- ROLES MODEL:
--   app_readonly      — SELECT on all tables in all schemas
--   app_readwrite     — SELECT + INSERT + UPDATE + DELETE on hr/sales/finance
--                       (audit is read-only for everyone except triggers)
--   analytics_reader  — SELECT only, with USAGE on materialized views
--
-- The master user (dbadmin) inherits superuser-like power on this DB and
-- isn't part of these app roles — apps would connect as dedicated users
-- granted into one of these roles. (Not provisioned here; create them on
-- demand with CREATE USER <x> IN ROLE app_readwrite PASSWORD '...'.)

\echo '== Creating schemas =='

CREATE SCHEMA IF NOT EXISTS hr      AUTHORIZATION dbadmin;
CREATE SCHEMA IF NOT EXISTS sales   AUTHORIZATION dbadmin;
CREATE SCHEMA IF NOT EXISTS finance AUTHORIZATION dbadmin;
CREATE SCHEMA IF NOT EXISTS audit   AUTHORIZATION dbadmin;

COMMENT ON SCHEMA hr      IS 'Human Resources: employees, departments, positions, payroll, leave.';
COMMENT ON SCHEMA sales   IS 'CRM + Sales: customers, contacts, products, orders, invoices.';
COMMENT ON SCHEMA finance IS 'General Ledger + budgets: chart of accounts, journals, fiscal periods.';
COMMENT ON SCHEMA audit   IS 'Append-only change log populated by per-table triggers.';

\echo '== Enabling required extensions =='

-- pgcrypto: gives us gen_random_uuid() for distributed-friendly PKs.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- citext: case-insensitive text type — used for emails so 'Alice@Foo.com'
-- and 'alice@foo.com' compare equal without manual lower() casts.
CREATE EXTENSION IF NOT EXISTS citext;

-- pg_stat_statements: query-fingerprint-based metrics (useful for the demo).
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\echo '== Creating reusable roles =='

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readonly') THEN
    CREATE ROLE app_readonly NOLOGIN;
    COMMENT ON ROLE app_readonly IS 'SELECT on all schemas. Group only — login users would be GRANTed into this role.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readwrite') THEN
    CREATE ROLE app_readwrite NOLOGIN;
    COMMENT ON ROLE app_readwrite IS 'SELECT/INSERT/UPDATE/DELETE on hr/sales/finance. Audit remains write-only-by-trigger.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analytics_reader') THEN
    CREATE ROLE analytics_reader NOLOGIN;
    COMMENT ON ROLE analytics_reader IS 'SELECT-only role intended for BI tools / read-replicas.';
  END IF;
END
$$;

\echo '== Granting schema USAGE =='

GRANT USAGE ON SCHEMA hr,      sales, finance, audit TO app_readonly, app_readwrite, analytics_reader;

-- Default privileges: any FUTURE table created in these schemas inherits
-- the right grants automatically. Run as dbadmin (the schema owner).
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA hr      GRANT SELECT ON TABLES TO app_readonly, analytics_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA sales   GRANT SELECT ON TABLES TO app_readonly, analytics_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA finance GRANT SELECT ON TABLES TO app_readonly, analytics_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA audit   GRANT SELECT ON TABLES TO app_readonly, analytics_reader;

ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA hr      GRANT INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA sales   GRANT INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA finance GRANT INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;

ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA hr      GRANT USAGE, SELECT ON SEQUENCES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA sales   GRANT USAGE, SELECT ON SEQUENCES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dbadmin IN SCHEMA finance GRANT USAGE, SELECT ON SEQUENCES TO app_readwrite;

\echo '== schemas + roles ready =='
