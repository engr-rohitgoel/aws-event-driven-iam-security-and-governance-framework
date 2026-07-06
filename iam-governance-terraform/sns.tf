resource "aws_sns_topic" "policy_evaluation_events" {
  name = "iam-policy-evaluation-events"
  tags = local.common_tags
}

resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
