# =============================================================================
# bastion-iam.tf — let the bastion role read THIS stack's secret + seed drops
# =============================================================================
#
# The seed job (in .github/workflows/terraform.yml) uses SSM SendCommand
# to make the bastion run psql against the new RDS instance. For that the
# bastion needs:
#
#   1. secretsmanager:GetSecretValue on the master credentials secret
#      created by this stack
#   2. s3:GetObject on the bootstrap state bucket prefix where the seed
#      bundle is dropped per-run
#
# Granted as INLINE policies on the existing bastion role (cluster-iac
# owns the role itself; we only attach narrow per-secret policies). This
# way destroying THIS stack also removes the grant.

# Discover the bastion role created by sbx-cluster-iac.
data "aws_iam_role" "bastion" {
  name = "sbx-bastion-role"
}

# Discover the bootstrap state bucket — used as a transient seed drop zone.
# Hardcoded by name to avoid a remote-state coupling (same convention as
# backend.tf above).
locals {
  state_bucket_name = "sbx-tfstate-784916389752-us-east-1"
}

# 1. Read this stack's master secret
resource "aws_iam_role_policy" "bastion_read_pg_secret" {
  name = "sbx-rds-pg-secret-read"
  role = data.aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = aws_secretsmanager_secret.master.arn
      },
    ]
  })
}

# 2. Read seed drop zones in the state bucket. Scoped to the seed-drops/
#    prefix so the bastion can NEVER fetch terraform state files.
resource "aws_iam_role_policy" "bastion_read_seed_drops" {
  name = "sbx-rds-pg-seed-drops-read"
  role = data.aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${local.state_bucket_name}/seed-drops/sbx-rds-pg-*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${local.state_bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["seed-drops/sbx-rds-pg-*", "seed-drops/sbx-rds-pg-*/*"]
          }
        }
      },
    ]
  })
}
