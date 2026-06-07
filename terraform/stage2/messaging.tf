# ============================================================
# SQS – DEAD LETTER QUEUES
# ============================================================

resource "aws_sqs_queue" "road_event_dlq" {
  name                      = "${var.environment}-road-event-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "user_data_dlq" {
  name                      = "${var.environment}-user-data-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "user_location_dlq" {
  name                      = "${var.environment}-user-location-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "statistics_dlq" {
  name                      = "${var.environment}-statistics-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "authorities_dlq" {
  name                      = "${var.environment}-authorities-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "archive_dlq" {
  name                      = "${var.environment}-archive-dlq"
  message_retention_seconds = 1209600

  tags = { Environment = var.environment }
}

# ============================================================
# SQS – MAIN QUEUES (with DLQ redrive)
# ============================================================

resource "aws_sqs_queue" "road_event" {
  name                       = "${var.environment}-road-event-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.road_event_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "user_data" {
  name                       = "${var.environment}-user-data-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.user_data_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "user_location" {
  name                       = "${var.environment}-user-location-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.user_location_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "statistics" {
  name                       = "${var.environment}-statistics-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.statistics_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "authorities" {
  name                       = "${var.environment}-authorities-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.authorities_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue" "archive" {
  name                       = "${var.environment}-archive-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.archive_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Environment = var.environment }
}

# ============================================================
# SNS – HIGH PRIORITY ROAD EVENTS TOPIC
# ============================================================

resource "aws_sns_topic" "road_events_completed" {
  name = "${var.environment}-road-events-completed"

  tags = { Environment = var.environment }
}

resource "aws_sqs_queue_policy" "statistics_sns" {
  queue_url = aws_sqs_queue.statistics.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.statistics.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.road_events_completed.arn }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "authorities_sns" {
  queue_url = aws_sqs_queue.authorities.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.authorities.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.road_events_completed.arn }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "archive_sns" {
  queue_url = aws_sqs_queue.archive.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.archive.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.road_events_completed.arn }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "statistics" {
  topic_arn            = aws_sns_topic.road_events_completed.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.statistics.arn
  raw_message_delivery = false
}

resource "aws_sns_topic_subscription" "authorities" {
  topic_arn            = aws_sns_topic.road_events_completed.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.authorities.arn
  raw_message_delivery = false
}

resource "aws_sns_topic_subscription" "archive" {
  topic_arn            = aws_sns_topic.road_events_completed.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.archive.arn
  raw_message_delivery = false
}
