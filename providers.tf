# =============================================================================
# providers.tf — AWS + random providers
# =============================================================================
#
# Single-region project; all resources land in the region declared in
# terraform.tfvars (default us-east-1). Default tags are applied to every
# AWS resource so cost-allocation reports + searches work without per-
# resource tag boilerplate.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = "sbx"
      stack      = "sbx-rds-postgres"
      managed_by = "terraform"
      owner      = var.owner_tag
      # cost_center is intentionally a constant — this stack is sandbox-only.
      cost_center = "sandbox"
    }
  }
}

provider "random" {}
