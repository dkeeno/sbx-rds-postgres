# =============================================================================
# rds.tf — RDS PostgreSQL instance + parameter/subnet groups
# =============================================================================
#
# Single instance, single AZ, gp3 storage, IAM auth disabled (sandbox uses
# password auth via Secrets Manager; productionization step would add IAM
# auth + DB users mapped to IAM principals).
#
# Architecture decisions:
#  - PostgreSQL 16.x — current LTS line, supports JSONB / generated columns
#    / range types / etc. used by the seed schema.
#  - db.t4g.micro — Graviton, cheapest. 1 vCPU / 1 GB RAM. Good enough for
#    a fictional dataset of ~few thousand rows total.
#  - storage_type = gp3 — no provisioning, baseline 3000 IOPS.
#  - performance_insights_enabled = true — even on micro instances, free
#    for the 7-day retention tier. Useful for the demo.
#  - cloudwatch_logs_exports = ["postgresql"] — capture errors + slow
#    queries; no log retention configured (default 30d).

# ---------- Parameter group ----------
# Custom params for sandbox visibility. Notably: log_statement = 'mod'
# captures DML in CloudWatch logs (helpful for seeing what the seed scripts
# actually executed).
resource "aws_db_parameter_group" "pg16" {
  name        = "${var.name_prefix}-rds-pg-params"
  family      = "postgres16"
  description = "Custom params for ${var.name_prefix} sandbox PostgreSQL: log DML, force_ssl on."

  # Force TLS on connections — clients must connect with sslmode=require.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Log all DML (INSERT/UPDATE/DELETE) — pairs well with the audit trigger
  # demo so you can see both PostgreSQL's own log AND the audit table.
  parameter {
    name  = "log_statement"
    value = "mod"
  }

  # Log queries slower than 250ms (sandbox-acceptable; production would
  # use pg_stat_statements + a higher threshold).
  parameter {
    name  = "log_min_duration_statement"
    value = "250"
  }

  # Increase work_mem so the materialized view refresh + analytical queries
  # don't spill to disk on the tiny micro instance. Static value (4MB) is
  # the t4g.micro default ceiling.
  parameter {
    name  = "work_mem"
    value = "4096" # KB
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Subnet group ----------
# Subnets MUST span 2+ AZs even for a single-AZ instance — RDS uses the
# extra subnet for the Multi-AZ standby IF you ever flip multi_az = true.
resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-rds-pg-subnets"
  description = "Private subnets for ${var.name_prefix} sandbox PostgreSQL."
  subnet_ids  = data.aws_subnets.private.ids

  tags = {
    Name = "${var.name_prefix}-rds-pg-subnets"
  }
}

# ---------- The instance itself ----------
resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-rds-pg"
  engine     = "postgres"
  # Use only the major.minor version; RDS auto-selects the latest patch.
  engine_version = var.db_engine_version

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage_gb
  storage_type      = var.db_storage_type
  storage_encrypted = true # Encryption at rest with the default AWS-managed KMS key.

  db_name  = var.db_name
  username = var.db_master_username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.pg16.name
  publicly_accessible    = var.db_publicly_accessible
  multi_az               = false # sandbox

  # Backup window: 1-day retention, no preferred time (RDS picks). Long
  # enough for point-in-time-restore (5-min granularity), short enough to
  # keep costs near zero.
  backup_retention_period = var.db_backup_retention_days
  copy_tags_to_snapshot   = true

  # Sandbox knobs
  skip_final_snapshot = var.db_skip_final_snapshot
  deletion_protection = var.db_deletion_protection

  # Observability — included with the instance, no extra cost on this size
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Auto minor-version upgrades during the maintenance window. Safe for
  # PG (no breaking schema changes within minor versions).
  auto_minor_version_upgrade = true
  apply_immediately          = true # sandbox; production would be false to defer to maintenance window

  tags = {
    Name = "${var.name_prefix}-rds-pg"
  }

  # If you re-import this resource to switch engines, the upgrade-in-place
  # would discard data — guard against accidents.
  lifecycle {
    ignore_changes = [
      # RDS rewrites this if Auto Minor Upgrade applies a patch — don't
      # diff on it next plan.
      engine_version,
    ]
  }
}
