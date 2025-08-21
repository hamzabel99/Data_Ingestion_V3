data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_sns_topic" "daily_monitor_topic" {
  name = "daily-monitor-topic"
}


resource "aws_sns_topic_subscription" "daily_monitor_topic_target" {
  topic_arn = aws_sns_topic.daily_monitor_topic.arn
  protocol  = "email"
  endpoint = var.email_target_monitoring
}