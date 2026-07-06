resource "aws_cloudwatch_event_rule" "iam_policy_api_events" {
  name        = "iam-policy-api-events"
  description = "Detect IAM policy creation, attachment, and update events"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName = [
        "AttachGroupPolicy",
        "AttachRolePolicy",
        "AttachUserPolicy",
        "CreatePolicy",
        "CreatePolicyVersion",
        "PutGroupPolicy",
        "PutRolePolicy",
        "PutUserPolicy",
        "SetDefaultPolicyVersion"
      ]
    }
  })

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_eventbridge_lambda1" {
  statement_id  = "AllowEventBridgeInvokeLambda1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda1.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_policy_api_events.arn
}

resource "aws_cloudwatch_event_target" "iam_policy_api_lambda1" {
  rule      = aws_cloudwatch_event_rule.iam_policy_api_events.name
  target_id = "iam-policy-change-audit"
  arn       = aws_lambda_function.lambda1.arn

  depends_on = [aws_lambda_permission.allow_eventbridge_lambda1]
}

resource "aws_cloudwatch_event_rule" "access_analyzer_findings" {
  name        = "access-analyzer-unused-access-findings"
  description = "Detect IAM Access Analyzer findings and invoke Lambda 4"

  event_pattern = jsonencode({
    source      = ["aws.access-analyzer"]
    detail-type = ["Access Analyzer Finding"]
  })

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_eventbridge_lambda4" {
  statement_id  = "AllowEventBridgeInvokeLambda4"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda4.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.access_analyzer_findings.arn
}

resource "aws_cloudwatch_event_target" "access_analyzer_lambda4" {
  rule      = aws_cloudwatch_event_rule.access_analyzer_findings.name
  target_id = "iam-unused-access-finding-alert"
  arn       = aws_lambda_function.lambda4.arn

  depends_on = [aws_lambda_permission.allow_eventbridge_lambda4]
}
