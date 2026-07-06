data "archive_file" "lambda1" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda1"
  output_path = "${path.module}/lambda1.zip"
}

data "archive_file" "lambda2" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda2"
  output_path = "${path.module}/lambda2.zip"
}

data "archive_file" "lambda3" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda3"
  output_path = "${path.module}/lambda3.zip"
}

data "archive_file" "lambda4" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda4"
  output_path = "${path.module}/lambda4.zip"
}

resource "aws_lambda_function" "lambda1" {
  function_name = local.lambda_names.lambda1
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda1.output_path
  source_code_hash = data.archive_file.lambda1.output_base64sha256

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.policy_evaluation_events.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "lambda2" {
  function_name = local.lambda_names.lambda2
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda2.output_path
  source_code_hash = data.archive_file.lambda2.output_base64sha256

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      ACCOUNT_ID    = local.account_id
      REGION        = var.region
      SOFT_FAIL     = "WARNING"
      HARD_FAIL     = "ERROR"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "lambda3" {
  function_name = local.lambda_names.lambda3
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda3.output_path
  source_code_hash = data.archive_file.lambda3.output_base64sha256

  timeout     = 120
  memory_size = 512

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      BUCKET        = aws_s3_bucket.privileged_actions.id
      KEY           = aws_s3_object.privileged_actions_file.key
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "lambda4" {
  function_name = local.lambda_names.lambda4
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda4.output_path
  source_code_hash = data.archive_file.lambda4.output_base64sha256

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_sns_lambda2" {
  statement_id  = "AllowSNSInvokeLambda2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda2.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.policy_evaluation_events.arn
}

resource "aws_lambda_permission" "allow_sns_lambda3" {
  statement_id  = "AllowSNSInvokeLambda3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda3.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.policy_evaluation_events.arn
}

resource "aws_sns_topic_subscription" "lambda2_subscription" {
  topic_arn = aws_sns_topic.policy_evaluation_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda2.arn

  depends_on = [aws_lambda_permission.allow_sns_lambda2]
}

resource "aws_sns_topic_subscription" "lambda3_subscription" {
  topic_arn = aws_sns_topic.policy_evaluation_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda3.arn

  depends_on = [aws_lambda_permission.allow_sns_lambda3]
}
