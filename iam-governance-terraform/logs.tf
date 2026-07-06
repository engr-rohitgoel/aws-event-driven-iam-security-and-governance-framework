resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_names

  name              = "/aws/lambda/${each.value}"
  retention_in_days = var.lambda_log_retention_days
  tags              = local.common_tags
}
