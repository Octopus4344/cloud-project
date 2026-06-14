locals {
  ecr_repositories = {
    authorities_service    = "authorities-service"
    road_event_service     = "road-event-service"
    statistics_service     = "statistics-service"
    user_data_service      = "user-data-service"
    user_location_service  = "user-location-service"
    frontend               = "road-events-frontend"
  }
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
