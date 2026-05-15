# =============================================================================
# outputs.tf — values you'll need after apply (for seeding + connecting)
# =============================================================================

output "endpoint" {
  description = "RDS endpoint hostname:port. Used by psql -h <endpoint>."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname (no port). For psql, port comes from -p 5432."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port (default 5432)."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database. All schemas (hr/sales/finance/audit) live inside it."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username (sensitive in production; sandbox-OK to expose)."
  value       = aws_db_instance.this.username
}

output "master_secret_arn" {
  description = "Secrets Manager ARN holding {username,password,engine,host,port,dbname} JSON. Fetch with `aws secretsmanager get-secret-value --secret-id <arn>`."
  value       = aws_secretsmanager_secret.master.arn
}

output "security_group_id" {
  description = "RDS instance security group (for cross-stack ingress)."
  value       = aws_security_group.rds.id
}

# -----------------------------------------------------------------------------
# Connection cheat sheet (printed on apply)
# -----------------------------------------------------------------------------
output "next_steps" {
  description = "How to connect + seed."
  value       = <<-EOT

    RDS PostgreSQL ready.

    1) Fetch the master password (one-time, store in your shell):
         export PGPASSWORD=$(aws secretsmanager get-secret-value \
           --secret-id ${aws_secretsmanager_secret.master.arn} \
           --region ${var.aws_region} \
           --query SecretString --output text | jq -r .password)

    2) Connect via SSM tunnel through the bastion (from your laptop):
         BASTION_ID=$(aws ec2 describe-instances --region ${var.aws_region} \
           --filters Name=tag:Name,Values=sbx-bastion-01 Name=instance-state-name,Values=running \
           --query "Reservations[0].Instances[0].InstanceId" --output text)
         aws ssm start-session \
           --target $BASTION_ID \
           --region ${var.aws_region} \
           --document-name AWS-StartPortForwardingSessionToRemoteHost \
           --parameters '{"host":["${aws_db_instance.this.address}"],"portNumber":["5432"],"localPortNumber":["15432"]}'
       (Leave this terminal open; tunnel uses local port 15432.)

    3) In ANOTHER terminal, run the seed scripts:
         cd seed
         for f in 01-*.sql 02-*.sql 03-*.sql 04-*.sql 05-*.sql 06-*.sql 07-*.sql 08-*.sql 09-*.sql 10-*.sql; do
           echo "Applying $f..."
           psql "host=localhost port=15432 user=${var.db_master_username} dbname=${var.db_name} sslmode=require" -v ON_ERROR_STOP=1 -f "$f"
         done

    4) Verify (still via the tunnel):
         psql "host=localhost port=15432 user=${var.db_master_username} dbname=${var.db_name} sslmode=require" \
           -c "SELECT schemaname, COUNT(*) AS tables FROM pg_tables WHERE schemaname IN ('hr','sales','finance','audit') GROUP BY schemaname;"
         psql "host=localhost port=15432 user=${var.db_master_username} dbname=${var.db_name} sslmode=require" \
           -c "SELECT COUNT(*) AS employees FROM hr.employees;"

    See README.md for the full schema + function inventory.
  EOT
}
