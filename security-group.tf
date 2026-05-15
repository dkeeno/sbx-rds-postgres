# =============================================================================
# security-group.tf — RDS network access
# =============================================================================
#
# Locked down by default: only the bastion SG can reach 5432. Optional
# additional CIDRs (e.g. user's laptop IP) can be added via tfvars when
# direct-from-laptop seeding is needed. There is NO 0.0.0.0/0 inbound
# under any configuration of this stack — even if db_publicly_accessible
# is true, the SG enforces source restrictions.

resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-pg-"
  description = "Inbound 5432 from bastion + optional CIDRs only. Outbound none required (RDS is server-only)."
  vpc_id      = data.aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-rds-pg-sg"
  }

  # name_prefix + lifecycle = avoid the "in-use" SG-rename collision when
  # other stacks reference this SG by ID.
  lifecycle {
    create_before_destroy = true
  }
}

# Inbound from bastion's SG (covers all SSM-tunneled psql access)
resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = data.aws_security_group.bastion.id
  description              = "PostgreSQL from sbx bastion (psql-via-SSM seeding)"
}

# Optional: inbound from explicit CIDRs (e.g. user's laptop IP for direct
# seeding when db_publicly_accessible = true). One rule per CIDR.
resource "aws_security_group_rule" "rds_from_extra_cidrs" {
  for_each = toset(var.additional_ingress_cidrs)

  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = [each.key]
  description       = "PostgreSQL from operator CIDR ${each.key}"
}
