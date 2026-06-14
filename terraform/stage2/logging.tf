locals {
  log_groups = {
    authorities_service   = "/ecs/authorities-service"
    road_event_service    = "/ecs/road-event-service"
    statistics_service    = "/ecs/statistics-service"
    user_data_service     = "/ecs/user-data-service"
    user_location_service = "/ecs/user-location-service"
    lambda_archive        = "/aws/lambda/archive-road-event"
    frontend              = "/ecs/road-events-frontend"
  }
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = 30
}
