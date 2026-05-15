#!/usr/bin/env bash
# =============================================================================
# run-seed.sh — orchestration script run on the bastion via SSM SendCommand
# =============================================================================
#
# Called from .github/workflows/terraform.yml (seed job). Expects three
# environment variables to be set by the caller:
#   RDS_HOST     — RDS endpoint hostname (no port)
#   SECRET_ARN   — Secrets Manager ARN holding the master credentials
#   AWS_REGION   — AWS region for the secret lookup
#   SEED_DROP    — local directory containing the .sql files (already populated)
#
# Idempotent — every seed file uses CREATE ... IF NOT EXISTS / ON CONFLICT
# so re-runs are safe.

set -euo pipefail

: "${RDS_HOST:?RDS_HOST not set}"
: "${SECRET_ARN:?SECRET_ARN not set}"
: "${AWS_REGION:?AWS_REGION not set}"
: "${SEED_DROP:?SEED_DROP not set}"

echo "=== Installing PostgreSQL 16 client ==="
# Amazon Linux 2023 ships postgresql15 by default; postgresql16 is in the
# default repo. Either works; psql client speaks PG16 wire protocol.
sudo dnf install -y postgresql16 2>&1 | tail -3 || sudo dnf install -y postgresql15 2>&1 | tail -3

echo "=== Fetching master password from Secrets Manager ==="
PGPASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$AWS_REGION" \
  --query SecretString --output text \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
export PGPASSWORD

CONN="host=$RDS_HOST port=5432 user=dbadmin dbname=enterprise_corp sslmode=require"

echo "=== Applying seed scripts in order ==="
for f in $(ls -1 "$SEED_DROP"/*.sql | sort); do
  echo ""
  echo "--- $(basename "$f") ---"
  psql "$CONN" -v ON_ERROR_STOP=1 -f "$f"
done

echo ""
echo "=== Verifying ==="
psql "$CONN" -c "SELECT schemaname, COUNT(*) AS tables
                 FROM pg_tables
                 WHERE schemaname IN ('hr','sales','finance','audit')
                 GROUP BY schemaname ORDER BY schemaname;"

psql "$CONN" -c "SELECT 'hr.employees'         AS table, COUNT(*) FROM hr.employees
                 UNION ALL SELECT 'hr.departments',          COUNT(*) FROM hr.departments
                 UNION ALL SELECT 'hr.payroll',              COUNT(*) FROM hr.payroll
                 UNION ALL SELECT 'sales.products',          COUNT(*) FROM sales.products
                 UNION ALL SELECT 'sales.customers',         COUNT(*) FROM sales.customers
                 UNION ALL SELECT 'sales.orders',            COUNT(*) FROM sales.orders
                 UNION ALL SELECT 'sales.invoices',          COUNT(*) FROM sales.invoices
                 UNION ALL SELECT 'finance.fiscal_periods',  COUNT(*) FROM finance.fiscal_periods
                 UNION ALL SELECT 'finance.journal_entries', COUNT(*) FROM finance.journal_entries
                 UNION ALL SELECT 'finance.journal_lines',   COUNT(*) FROM finance.journal_lines
                 UNION ALL SELECT 'audit.change_log',        COUNT(*) FROM audit.change_log;"

echo ""
echo "=== Sample function call ==="
psql "$CONN" -c "SELECT hr.calculate_tenure_years(1) AS ceo_tenure_years;"

unset PGPASSWORD
echo ""
echo "=== Seed complete ==="
