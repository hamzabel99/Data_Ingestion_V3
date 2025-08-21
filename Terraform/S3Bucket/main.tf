resource "aws_s3_bucket" "preprocess_bucket" {
  bucket = var.preprocess_bucket_name
}

resource "aws_s3_bucket" "postprocess_bucket" {
  bucket = var.postprocess_bucket_name
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = var.artifacts_bucket_name
}