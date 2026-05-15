# =============================================================================
# versions.tf — Terraform + provider version pinning
# =============================================================================
#
# This stack is INTENTIONALLY isolated from the cluster-iac stack:
#  - Uses its OWN S3 state key (see backend.tf)
#  - Reuses the cluster's VPC + private subnets via data sources, NOT remote
#    state (so this stack can be destroyed/recreated without coordinating)
#  - Has no dependency on, and is not depended on by, any app or pipeline
#
# Provider rationale:
#  - aws ~> 5.80     for RDS, Secrets Manager, security groups
#  - random ~> 3.6   for the master password generator (random_password)
#  - tls (none)      we don't terminate TLS here; RDS provides default cert

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
