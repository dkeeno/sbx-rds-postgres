# =============================================================================
# vpc-data.tf — discover the existing project VPC + private subnets
# =============================================================================
#
# This stack is intentionally decoupled from sbx-cluster-iac's terraform
# state. We DON'T use data.terraform_remote_state — that would create a
# tight coupling and require coordinated destroys.
#
# Instead: find the VPC + subnets by NAME TAG. If those tags ever change,
# update terraform.tfvars accordingly. The VPC + subnets are owned by
# sbx-cluster-iac; this stack is read-only against them.

# Find the project VPC by its Name tag
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_tag]
  }
}

# Find all private subnets matching the wildcard pattern (one per AZ).
# RDS subnet group requires 2+ subnets in different AZs even for single-AZ.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.private_subnet_name_pattern]
  }
}

# Find the bastion's security group so we can grant it ingress on 5432.
# This is a soft dependency: if the bastion stack is destroyed, this
# lookup fails — but the bastion is part of the cluster-iac stack which
# is the long-lived parent. Acceptable coupling for sandbox.
data "aws_security_group" "bastion" {
  name   = var.bastion_security_group_name
  vpc_id = data.aws_vpc.this.id
}
