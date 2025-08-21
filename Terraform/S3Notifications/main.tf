resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.preprocess_bucket_name

  queue {
    queue_arn = var.preprocess_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [var.sqs_queue_policy_id]
}
