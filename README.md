# sbx-rds-postgres

Standalone Terraform stack provisioning a small PostgreSQL RDS instance + a fictional enterprise database (`enterprise_corp`) under the company name **"Helix Atlas Industrial Ltd"**.

> **Isolated stack:** no connection to the apps (`online-shop` / `art-gallery`) or to the GitOps pipeline. Created purely as a database playground / demo.

## What's in the database

| Schema | Purpose | Tables |
|---|---|---|
| `hr` | People & payroll | `departments`, `positions`, `employees`, `payroll`, `leave_requests` |
| `sales` | CRM + orders | `products`, `customers`, `contacts`, `opportunities`, `orders`, `order_items`, `invoices` |
| `finance` | General Ledger | `fiscal_periods`, `chart_of_accounts`, `journal_entries`, `journal_lines`, `budgets` |
| `audit` | Append-only change log | `change_log` (populated by triggers) |

**Seed volume:** 80 employees, 8 departments, 25 products, 40 customers, 41 contacts, 40 opportunities, 20 orders, ~50 line items, 16 invoices, 12 fiscal periods, 30 GL accounts, 132 budget rows, 12 journal entries with balanced double-entry lines.

**Functions:**
- `audit.log_change()` — universal AFTER row trigger writing JSONB diffs to `audit.change_log`
- `audit.tg_set_updated_at()` — BEFORE UPDATE row trigger bumping `updated_at`
- `hr.calculate_tenure_years(employee_id)` — years employed (handles terminated employees)
- `hr.fn_employee_full_record(employee_id)` — JSONB blob: employee + dept + position + manager + tenure
- `sales.calc_order_total(order_id)` — sum of line totals
- `sales.tg_refresh_order_total()` — keeps `orders.total_amount` accurate after order_items change
- `finance.fiscal_period_for_date(date)` — period lookup
- `finance.tg_check_journal_balance()` — CONSTRAINT TRIGGER: rejects unbalanced entries

**Views:**
- `hr.v_active_employees` — currently-employed roster, joined to dept + position
- `sales.v_open_invoices` — unpaid invoices with overdue calculation
- `sales.v_pipeline_by_rep` — pipeline metrics per sales rep
- `finance.v_account_balances` — posted journal balances per account, signed by normal_balance

**Materialized views:**
- `sales.mv_monthly_revenue_by_category` — refresh after big imports
- `sales.mv_customer_lifetime_value` — refresh nightly

**Roles:**
- `app_readonly` — SELECT on all schemas
- `app_readwrite` — SELECT/INSERT/UPDATE/DELETE on hr/sales/finance
- `analytics_reader` — SELECT-only with USAGE on materialized views

## Apply the stack

Per HARD RULE `feedback_mcp_first_no_manual` + `feedback_pr_only_no_direct_main`: this stack should land via PR + GitHub Actions, NOT a local apply. Until then (or for one-off sandbox apply), use:

```sh
cd github-terraform-aws/sbx-iac/sbx-rds-postgres

# Source the GitHub PAT (only needed if you wire up the GitHub provider later)
# set -o allexport && source ~/.mcp-servers/github-mcp-server/.env && set +o allexport

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Apply takes ~10 minutes (RDS instance provision is the slow piece).

## Seed the database

The seed scripts (`seed/01-…sql` through `seed/10-…sql`) execute via `psql` after the instance is up. The instance is in a private subnet, so connect through the bastion via SSM port-forward.

```sh
# 1. Get the master password
export PGPASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id sbx-rds-pg-master-credentials \
  --region us-east-1 \
  --query SecretString --output text | jq -r .password)

# 2. Open SSM port-forward through the bastion (LEAVE THIS RUNNING)
BASTION_ID=$(aws ec2 describe-instances --region us-east-1 \
  --filters Name=tag:Name,Values=sbx-bastion-01 Name=instance-state-name,Values=running \
  --query "Reservations[0].Instances[0].InstanceId" --output text)
RDS_HOST=$(terraform output -raw address)
aws ssm start-session \
  --target $BASTION_ID \
  --region us-east-1 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$RDS_HOST\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"15432\"]}"

# 3. In ANOTHER terminal, run the seed scripts in order
cd seed
for f in $(ls 0*.sql | sort); do
  echo "=== Applying $f ==="
  psql "host=localhost port=15432 user=dbadmin dbname=enterprise_corp sslmode=require" \
    -v ON_ERROR_STOP=1 -f "$f"
done
```

## Verify

```sh
psql "host=localhost port=15432 user=dbadmin dbname=enterprise_corp sslmode=require" <<'EOF'
-- Schema/table inventory
SELECT schemaname, COUNT(*) AS tables
FROM pg_tables
WHERE schemaname IN ('hr','sales','finance','audit')
GROUP BY schemaname ORDER BY schemaname;

-- Row counts
SELECT 'hr.employees'  AS t, COUNT(*) FROM hr.employees
UNION ALL SELECT 'hr.departments',          COUNT(*) FROM hr.departments
UNION ALL SELECT 'hr.payroll',              COUNT(*) FROM hr.payroll
UNION ALL SELECT 'sales.customers',         COUNT(*) FROM sales.customers
UNION ALL SELECT 'sales.orders',            COUNT(*) FROM sales.orders
UNION ALL SELECT 'sales.invoices',          COUNT(*) FROM sales.invoices
UNION ALL SELECT 'finance.journal_entries', COUNT(*) FROM finance.journal_entries
UNION ALL SELECT 'finance.journal_lines',   COUNT(*) FROM finance.journal_lines
UNION ALL SELECT 'audit.change_log',        COUNT(*) FROM audit.change_log;

-- Try the active-employees view
SELECT COUNT(*) AS active_employees FROM hr.v_active_employees;

-- Try a function
SELECT hr.calculate_tenure_years(1) AS ceo_tenure_years;

-- Trial-balance check (debits should equal credits across all posted journals)
SELECT account_class,
       SUM(total_debits)  AS debits,
       SUM(total_credits) AS credits
FROM finance.v_account_balances
GROUP BY account_class;
EOF
```

## Cost

| Component | Monthly |
|---|---|
| RDS db.t4g.micro single-AZ | ~$13 |
| 20 GB gp3 storage | ~$2 |
| Backup storage (1-day retention) | ~$0.50 |
| Secrets Manager | $0.40 |
| **Total** | **~$16/mo** |

## Tear down

```sh
terraform destroy
# When prompted: yes
```

Takes ~5 min. With `db_skip_final_snapshot = true` (sandbox default), no snapshot is retained — the database disappears completely.
