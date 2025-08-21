data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for All Lambda functions
data "aws_iam_policy_document" "daily_monitor_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "daily_monitor_lambda_role" {
  name               = "daily_monitor_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.daily_monitor_lambda_assume_role.json
}


data "aws_iam_policy_document" "daily_monitor_lambda_policy" {
  
  statement {
    sid    = "SQSPoller"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      "arn:aws:sqs:eu-west-3:195044943814:Preprocess_Queue"
    ]
  }

    statement {
    sid    = "SNSSubscription"
    effect = "Allow"
    actions = [
        "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.daily_monitor_topic_name}"
    ]
  }


  statement {
    sid    = "DynamoReadWorkflowMetadata"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/workflow_statut"
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
  }
}


resource "aws_iam_role_policy" "daily_monitor_lambda_permissions" {
  name   = "lambda_permissions"
  role   = aws_iam_role.daily_monitor_lambda_role.id
  policy = data.aws_iam_policy_document.daily_monitor_lambda_policy.json
}


data "archive_file" "data_daily_monitor_lambda" {
  type        = "zip"
  source_file = "${path.module}/../Code/daily_monitor_lambda/daily_monitor_lambda.py"
  output_path = "${path.module}/../Code/daily_monitor_lambda/daily_monitor_lambda.zip"
}


resource "aws_lambda_function" "daily_monitor_lambda" {
  filename      = data.archive_file.data_daily_monitor_lambda.output_path
  function_name = "daily_monitor_lambda"
  role          = aws_iam_role.daily_monitor_lambda_role.arn
  handler       = "daily_monitor_lambda.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      WORKFLOW_TRACK_TABLE    = "workflow_statut",
      SNS_TOPIC_ARN           = var.daily_monitor_topic_arn
    }
  }
}