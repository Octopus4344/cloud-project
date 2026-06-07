# ============================================================
# ECR REPOSITORIES
# ============================================================

resource "aws_ecr_repository" "authorities_service" {
  name                 = "authorities-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "road_event_service" {
  name                 = "road-event-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "statistics_service" {
  name                 = "statistics-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "user_data_service" {
  name                 = "user-data-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "user_location_service" {
  name                 = "user-location-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "road-events-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
