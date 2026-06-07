# ============================================================
# CLOUDWATCH ALARMS
# ============================================================

locals {
  dlq_queues = {
    road_event  = aws_sqs_queue.road_event_dlq.name
    user_data   = aws_sqs_queue.user_data_dlq.name
    user_loc    = aws_sqs_queue.user_location_dlq.name
    statistics  = aws_sqs_queue.statistics_dlq.name
    authorities = aws_sqs_queue.authorities_dlq.name
    archive     = aws_sqs_queue.archive_dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  for_each = local.dlq_queues

  alarm_name          = "${var.environment}-${each.key}-dlq-messages"
  alarm_description   = "Messages appearing in ${each.value} – processing failures detected"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  namespace           = "AWS/SQS"
  metric_name         = "NumberOfMessagesSent"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = []

  tags = { Environment = var.environment }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  alarm_description   = "ALB is returning 5xx errors – application errors detected"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  evaluation_periods  = 2
  period              = 60
  statistic           = "Sum"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = []

  tags = { Environment = var.environment }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-archive-errors"
  alarm_description   = "Lambda archive function is producing errors"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"

  dimensions = {
    FunctionName = aws_lambda_function.archive_road_event.function_name
  }

  alarm_actions = []

  tags = { Environment = var.environment }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.environment}-lambda-archive-duration"
  alarm_description   = "Lambda archive function execution time is high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 45000
  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"

  dimensions = {
    FunctionName = aws_lambda_function.archive_road_event.function_name
  }

  alarm_actions = []

  tags = { Environment = var.environment }
}
