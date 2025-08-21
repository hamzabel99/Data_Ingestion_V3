variable "preprocess_bucket_name" {
  description = "Id of the preprocess bucket"
  type        = string

}

variable "preprocess_queue_arn" {
  description = "ARN of the preprocess queue"
  type        = string

}

variable "sqs_queue_policy_id" {
  description = "ID the queue policy"
  type        = string

}