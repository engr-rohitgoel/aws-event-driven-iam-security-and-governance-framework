data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  lambda_names = {
    lambda1 = "iam-policy-change-audit"
    lambda2 = "iam-policy-validator"
    lambda3 = "iam-privileged-action-checker"
    lambda4 = "iam-unused-access-finding-alert"
  }

  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
