# =============================================================================
# secrets.tf — generated master password + Secrets Manager record
# =============================================================================
#
# Never check a database password into git. Generate one at apply time and
# store it in Secrets Manager — both the bastion and any future app can
# fetch it via IAM with no shared-state ceremony.
#
# Rotation: out of scope for the sandbox. To rotate manually:
#   1. Generate a new strong password
#   2. ALTER USER dbadmin WITH PASSWORD '<new>';
#   3. aws secretsmanager put-secret-value --secret-id <arn> \
#        --secret-string '{"username":"dbadmin","password":"<new>"}'
# Or attach a Lambda rotation function (productionization step).

# Strong, RDS-compatible password.
# RDS forbids /, @, ", and space in master passwords — exclude them.
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager secret. The actual value is a JSON blob — the standard
# format AWS RDS / Lambda rotation expects.
resource "aws_secretsmanager_secret" "master" {
  name        = "${var.name_prefix}-rds-pg-master-credentials"
  description = "Master credentials for ${var.name_prefix}-rds-pg PostgreSQL instance."

  # Sandbox: 0-day recovery window means terraform destroy → secret gone
  # immediately, no zombie secrets accruing storage cost.
  recovery_window_in_days = 0
}

# Initial version of the secret. Subsequent rotations would create new
# versions (AWSCURRENT / AWSPENDING staging labels).
resource "aws_secretsmanager_secret_version" "master_v1" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })

  # Defer the version creation until the RDS instance has its endpoint —
  # otherwise the secret blob would be missing host/port. Reapply ordering
  # is handled by the implicit reference to aws_db_instance.this above.
}
