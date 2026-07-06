output "policy_evaluation_topic_arn" {
  value = aws_sns_topic.policy_evaluation_events.arn
}

output "security_alerts_topic_arn" {
  value = aws_sns_topic.security_alerts.arn
}

output "privileged_actions_bucket_name" {
  value = aws_s3_bucket.privileged_actions.id
}

output "unused_access_analyzer_arn" {
  value = aws_accessanalyzer_analyzer.unused_access.arn
}

output "eventbridge_iam_rule_name" {
  value = aws_cloudwatch_event_rule.iam_policy_api_events.name
}

output "eventbridge_access_analyzer_rule_name" {
  value = aws_cloudwatch_event_rule.access_analyzer_findings.name
}

output "lambda_function_names" {
  value = local.lambda_names
}
