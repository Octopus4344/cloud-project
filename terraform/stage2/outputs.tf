# ============================================================
# OUTPUTS
# ============================================================

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "road_event_service_url" {
  value = "http://${aws_lb.main.dns_name}/road-events"
}

output "user_data_service_url" {
  value = "http://${aws_lb.main.dns_name}/user-data"
}

output "user_location_service_url" {
  value = "http://${aws_lb.main.dns_name}/user-location"
}

output "statistics_service_url" {
  value = "http://${aws_lb.main.dns_name}/statistics"
}

output "authorities_service_url" {
  value = "http://${aws_lb.main.dns_name}/authorities"
}

output "frontend_url" {
  value       = "http://${aws_lb.main.dns_name}/app"
  description = "Frontend URL"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "Cognito User Pool ID"
}

output "cognito_app_client_id" {
  value       = aws_cognito_user_pool_client.main.id
  description = "Cognito App Client ID"
}

output "sqs_road_event_queue_url" {
  value = aws_sqs_queue.road_event.url
}

output "sqs_user_data_queue_url" {
  value = aws_sqs_queue.user_data.url
}

output "sqs_user_location_queue_url" {
  value = aws_sqs_queue.user_location.url
}

output "sqs_statistics_queue_url" {
  value = aws_sqs_queue.statistics.url
}

output "sqs_authorities_queue_url" {
  value = aws_sqs_queue.authorities.url
}

output "sns_road_events_completed_arn" {
  value = aws_sns_topic.road_events_completed.arn
}

output "s3_archive_bucket" {
  value = aws_s3_bucket.road_events_archive.bucket
}

output "dynamodb_road_events_table" {
  value = aws_dynamodb_table.road_events.name
}

output "dynamodb_users_table" {
  value = aws_dynamodb_table.users.name
}

output "dynamodb_statistics_table" {
  value = aws_dynamodb_table.statistics.name
}

output "ecr_road_event_service_repository_url" {
  value = aws_ecr_repository.road_event_service.repository_url
}

output "ecr_user_data_service_repository_url" {
  value = aws_ecr_repository.user_data_service.repository_url
}

output "ecr_user_location_service_repository_url" {
  value = aws_ecr_repository.user_location_service.repository_url
}

output "ecr_statistics_service_repository_url" {
  value = aws_ecr_repository.statistics_service.repository_url
}

output "ecr_authorities_service_repository_url" {
  value = aws_ecr_repository.authorities_service.repository_url
}

output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}
