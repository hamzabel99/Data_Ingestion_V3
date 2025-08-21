provider "aws" {
  region = "eu-west-3"
}

module "Dynamodb" {
  source = "./DynamoDb"
}

module "S3Bucket" {
  source                  = "./S3Bucket"
  preprocess_bucket_name  = "preworkflow-ingestion-bucket"
  postprocess_bucket_name = "postworkflow-ingestion-bucket"
  artifacts_bucket_name   = "gluejobs-ingestion-bucket"
}

module "Sqs" {
  source                = "./Sqs"
  preprocess_queue_name = "Preprocess_Queue"
  preprocess_bucket_arn = module.S3Bucket.preprocess_bucket_arn
}

module "S3Notifications" {
  source                 = "./S3Notifications"
  preprocess_bucket_name = module.S3Bucket.preprocess_bucket_name
  preprocess_queue_arn   = module.Sqs.preprocess_queue_arn
  sqs_queue_policy_id    = module.Sqs.queue_policy_id
}

module "start-workflow-lambda" {
  source            = "./Lambda/start-workflow-lambda"
}

module "end-workflow-lambda" {
  source            = "./Lambda/end-workflow-lambda"
}

module "files_to_process_lambda" {
  source            = "./Lambda/files_to_process_lambda"
  aws_sqs_queue_arn = module.Sqs.preprocess_queue_arn

}

module "glue-job"{
  source = "./Glue/ingestion-glue-job"
  artifacts_bucket_name = module.S3Bucket.artifacts_bucket_name
}

module "stepfunctions" {
  source ="./Stepfunction"
  end_workflow_lambda_arn = module.end-workflow-lambda.end_workflow_lambda_arn
  ingestion_glue_job_name = module.glue-job.ingestion_glue_job_name
}

module "sns" {
  source ="./Sns"
  email_target_monitoring = "hamza.belabbes@ens2m.org"
}

module "daily_monitor_lambda" {
  source ="./Lambda/daily_monitor_lambda"
  daily_monitor_topic_name =module.sns.daily_monitor_topic_name
  daily_monitor_topic_arn = module.sns.daily_monitor_topic_arn
}

module "eventbridge" {
  source = "./Eventbridge"
  daily_monitor_lambda_arn = module.daily_monitor_lambda.daily_monitor_lambda_arn
  start_workflow_lambda_arn = module.start-workflow-lambda.start_workflow_lambda_arn
}