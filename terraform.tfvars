# =============================================================================
# terraform.tfvars — concrete sandbox values
# =============================================================================
# All values committed (sandbox; the master password is generated, never
# committed). Override any of these via -var-file= for non-sandbox use.

aws_region  = "us-east-1"
name_prefix = "sbx"
owner_tag   = "dkeeno"

vpc_name_tag                = "sbx-vpc"
private_subnet_name_pattern = "sbx-private-*"
bastion_security_group_name = "sbx-bastion-sg"

# Add your laptop's public IP/32 here ONLY when you want to seed from local
# psql + you've also flipped db_publicly_accessible to true. Example:
#   additional_ingress_cidrs = ["203.0.113.42/32"]
additional_ingress_cidrs = []

db_instance_class       = "db.t4g.micro"
db_engine_version       = "16.4"
db_allocated_storage_gb = 20
db_storage_type         = "gp3"
db_name                 = "enterprise_corp"
db_master_username      = "dbadmin"

# Sandbox-friendly defaults
db_backup_retention_days = 1
db_publicly_accessible   = false
db_skip_final_snapshot   = true
db_deletion_protection   = false
