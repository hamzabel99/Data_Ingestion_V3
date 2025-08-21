data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for All Lambda functions
data "aws_iam_policy_document" "files_to_process_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "files_to_process_lambda_role" {
  name               = "files_to_process_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.files_to_process_lambda_assume_role.json
}


data "aws_iam_policy_document" "files_to_process_lambda_policy" {
  
  statement {
    sid    = "SQSPoller"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      "arn:aws:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:Preprocess_Queue"
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


resource "aws_iam_role_policy" "files_to_process_lambda_permissions" {
  name   = "lambda_permissions"
  role   = aws_iam_role.files_to_process_lambda_role.id
  policy = data.aws_iam_policy_document.files_to_process_lambda_policy.json
}


data "archive_file" "data_files_to_process_lambda" {
  type        = "zip"
  source_file = "${path.module}/../Code/files_to_process_lambda/files_to_process_lambda.py"
  output_path = "${path.module}/../Code/files_to_process_lambda/files_to_process_lambda.zip"
}


resource "aws_lambda_function" "files_to_process_lambda" {
  filename      = data.archive_file.data_files_to_process_lambda.output_path
  function_name = "files_to_process_lambda"
  role          = aws_iam_role.files_to_process_lambda_role.arn
  handler       = "files_to_process_lambda.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      WORKFLOW_TRACK_TABLE    = "workflow_statut"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger_lambda" {
  event_source_arn = var.aws_sqs_queue_arn
  function_name    = aws_lambda_function.files_to_process_lambda.arn
  batch_size       = 10
}