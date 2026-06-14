# ============================================================
# ECS TASK DEFINITIONS (EC2 launch type)
# ============================================================

resource "aws_ecs_task_definition" "road_event_service" {
  family                   = "road-event-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "road-event-service"
    image     = "${aws_ecr_repository.service["road_event_service"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3000, hostPort = 3000 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_ROAD_EVENT_QUEUE_URL", value = aws_sqs_queue.road_event.url },
      { name = "SQS_USER_DATA_QUEUE_URL", value = aws_sqs_queue.user_data.url },
      { name = "SQS_USER_LOCATION_QUEUE_URL", value = aws_sqs_queue.user_location.url },
      { name = "SNS_ROAD_EVENTS_COMPLETED_ARN", value = aws_sns_topic.road_events_completed.arn },
      { name = "DYNAMODB_ROAD_EVENTS_TABLE", value = aws_dynamodb_table.road_events.name },
      { name = "DYNAMODB_EVENT_STATUS_TABLE", value = aws_dynamodb_table.event_status.name },
      { name = "COGNITO_USER_POOL_ID", value = aws_cognito_user_pool.main.id },
      { name = "COGNITO_APP_CLIENT_ID", value = aws_cognito_user_pool_client.main.id },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["road_event_service"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

resource "aws_ecs_task_definition" "user_data_service" {
  family                   = "user-data-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "user-data-service"
    image     = "${aws_ecr_repository.service["user_data_service"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3001, hostPort = 3001 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_USER_DATA_QUEUE_URL", value = aws_sqs_queue.user_data.url },
      { name = "SQS_ROAD_EVENT_QUEUE_URL", value = aws_sqs_queue.road_event.url },
      { name = "DYNAMODB_USERS_TABLE", value = aws_dynamodb_table.users.name },
      { name = "COGNITO_USER_POOL_ID", value = aws_cognito_user_pool.main.id },
      { name = "COGNITO_APP_CLIENT_ID", value = aws_cognito_user_pool_client.main.id },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["user_data_service"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

resource "aws_ecs_task_definition" "user_location_service" {
  family                   = "user-location-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "user-location-service"
    image     = "${aws_ecr_repository.service["user_location_service"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3004, hostPort = 3004 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_USER_LOCATION_QUEUE_URL", value = aws_sqs_queue.user_location.url },
      { name = "SQS_ROAD_EVENT_QUEUE_URL", value = aws_sqs_queue.road_event.url },
      { name = "DYNAMODB_LOCATIONS_TABLE", value = aws_dynamodb_table.locations.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["user_location_service"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

resource "aws_ecs_task_definition" "statistics_service" {
  family                   = "statistics-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "statistics-service"
    image     = "${aws_ecr_repository.service["statistics_service"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3005, hostPort = 3005 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_STATISTICS_QUEUE_URL", value = aws_sqs_queue.statistics.url },
      { name = "DYNAMODB_STATISTICS_TABLE", value = aws_dynamodb_table.statistics.name },
      { name = "S3_ARCHIVE_BUCKET", value = aws_s3_bucket.road_events_archive.bucket },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["statistics_service"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

resource "aws_ecs_task_definition" "authorities_service" {
  family                   = "authorities-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "authorities-service"
    image     = "${aws_ecr_repository.service["authorities_service"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3006, hostPort = 3006 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_AUTHORITIES_QUEUE_URL", value = aws_sqs_queue.authorities.url },
      { name = "SNS_ROAD_EVENTS_COMPLETED_ARN", value = aws_sns_topic.road_events_completed.arn },
      { name = "DYNAMODB_INCIDENTS_TABLE", value = aws_dynamodb_table.incidents.name },
      { name = "S3_ARCHIVE_BUCKET", value = aws_s3_bucket.road_events_archive.bucket },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["authorities_service"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "road-events-frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "road-events-frontend"
    image     = "${aws_ecr_repository.service["frontend"].repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 80, hostPort = 80 }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service["frontend"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}
