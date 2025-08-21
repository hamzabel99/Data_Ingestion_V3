resource "aws_sqs_queue" "preprocess_queue" {
  name                       = var.preprocess_queue_name
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.preprocess_queue_name}-dlq"
}

resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.preprocess_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action   = "SQS:SendMessage",
      Resource = aws_sqs_queue.preprocess_queue.arn,
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = var.preprocess_bucket_arn
        }
      }
    }]
  })
}
