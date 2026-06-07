# ============================================================
# CLOUDWATCH LOG GROUPS
# ============================================================

resource "aws_cloudwatch_log_group" "authorities_service" {
  name              = "/ecs/authorities-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "road_event_service" {
  name              = "/ecs/road-event-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "statistics_service" {
  name              = "/ecs/statistics-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "user_data_service" {
  name              = "/ecs/user-data-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "user_location_service" {
  name              = "/ecs/user-location-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_archive" {
  name              = "/aws/lambda/archive-road-event"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/road-events-frontend"
  retention_in_days = 30
}
