resource "aws_glue_job" "etl_job" {
  name              = "ingestion-glue-job"
  description       = "CSV to Parquet Glue Job"
  role_arn          = aws_iam_role.glue_job_role.arn
  glue_version      = "3.0"
  max_retries       = 0
  timeout           = 2880
  number_of_workers = 2
  worker_type       = "G.1X"
  execution_class   = "STANDARD"

  command {
    script_location = "s3://${var.artifacts_bucket_name}/gluejob/ingestion-glue-job.py"
    name            = "glueetl"
    python_version  = "3"
  }

  notification_property {
    notify_delay_after = 3
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
    "--enable-auto-scaling"              = "true"
  }

  execution_property {
    max_concurrent_runs = 2
  }
}

# IAM role for Glue jobs
resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_s3_object" "glue_etl_script" {
  bucket = var.artifacts_bucket_name
  key    = "gluejob/ingestion-glue-job.py"
  source = "${path.module}/../Code/ingestion-glue-job/ingestion-glue-job.py" 
}
