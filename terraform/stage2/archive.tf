# ============================================================
# S3 – ROAD EVENTS ARCHIVE BUCKET
# ============================================================

resource "aws_s3_bucket" "road_events_archive" {
  bucket        = "${var.environment}-events-archive-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "road_events_archive" {
  bucket = aws_s3_bucket.road_events_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "road_events_archive" {
  bucket = aws_s3_bucket.road_events_archive.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "road_events_archive" {
  bucket                  = aws_s3_bucket.road_events_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# LAMBDA – ARCHIVE ROAD EVENTS TO S3
# ============================================================

resource "aws_lambda_function" "archive_road_event" {
  filename         = data.archive_file.lambda_archive_func.output_path
  source_code_hash = data.archive_file.lambda_archive_func.output_base64sha256
  function_name    = "${var.environment}-archive-road-event"
  role             = aws_iam_role.lambda_archive.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      AWS_ACCOUNT_REGION = var.aws_region
      ARCHIVE_BUCKET     = aws_s3_bucket.road_events_archive.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_archive]

  tags = {
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "archive_sqs" {
  event_source_arn                   = aws_sqs_queue.archive.arn
  function_name                      = aws_lambda_function.archive_road_event.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true
}
