output "preprocess_queue_arn" {
  value = aws_sqs_queue.preprocess_queue.arn
}

output "queue_policy_id" {
  value = aws_sqs_queue_policy.allow_s3.id
}
