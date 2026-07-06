variable "region" {
  description = "AWS region where the solution will be deployed. IAM events are global but delivered via CloudTrail/EventBridge in the configured region."
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address that will receive final security alerts from SNS. You must confirm the SNS subscription email after terraform apply."
  type        = string
}

variable "project_name" {
  description = "Prefix used for IAM roles and common tags."
  type        = string
  default     = "iam-governance"
}

variable "unused_access_age" {
  description = "Number of days after which IAM access is considered unused by IAM Access Analyzer."
  type        = number
  default     = 90
}

variable "lambda_log_retention_days" {
  description = "CloudWatch Logs retention period for Lambda log groups."
  type        = number
  default     = 30
}
