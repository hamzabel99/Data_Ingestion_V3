resource "aws_cloudwatch_event_rule" "daily_data_monitoring_trigger" {
  name        = "Daily_data_monitoring_trigger"
  description = "Triggers monitoring lambda every day"
  schedule_expression = "cron(0 0 1 1,7 ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_target_daily_monitor_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_data_monitoring_trigger.name
  target_id = "Monitoring_Lambda"
  arn       = var.daily_monitor_lambda_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_daily_data_monitoring_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.daily_monitor_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_data_monitoring_trigger.arn
}




resource "aws_cloudwatch_event_rule" "start_workflow_lambda_trigger" {
  name        = "start_workflow_lambda_trigger"
  description = "Triggers starting workflow execution lambda every .... ?"
  schedule_expression = "cron(0 0 1 1,7 ? *)"
}

resource "aws_cloudwatch_event_target" "target_trigger_start_workflow_lambda" {
  rule      = aws_cloudwatch_event_rule.start_workflow_lambda_trigger.name
  target_id = "start_workflow_lambda"
  arn       = var.start_workflow_lambda_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_start_workflow_lambda_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.start_workflow_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_workflow_lambda_trigger.arn
}


