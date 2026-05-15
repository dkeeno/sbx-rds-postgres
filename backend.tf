# =============================================================================
# backend.tf — S3 + DynamoDB remote state (shared backend, isolated key)
# =============================================================================
#
# Backend bucket + lock table are the ones provisioned by the bootstrap stack
# (github-terraform-aws/bootstrap/). We DON'T provision them here — they
# pre-exist as project-wide infrastructure shared by every stack.
#
# `key` MUST be unique per stack — otherwise two stacks would clobber each
# other's state. Convention: <subgroup>/<repo-or-folder>.tfstate.

terraform {
  backend "s3" {
    bucket         = "sbx-tfstate-784916389752-us-east-1"
    key            = "sbx-iac/sbx-rds-postgres.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sbx-tfstate-locks"
    encrypt        = true
  }
}
