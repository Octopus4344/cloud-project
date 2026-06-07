# ============================================================
# ECS SERVICES (EC2 via capacity provider)
# ============================================================

resource "aws_ecs_service" "road_event_service" {
  name            = "road-event-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.road_event_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.road_event_service.arn
    container_name   = "road-event-service"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http, aws_ecs_cluster_capacity_providers.main]

  tags = { Environment = var.environment }
}

resource "aws_ecs_service" "user_data_service" {
  name            = "user-data-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_data_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_data_service.arn
    container_name   = "user-data-service"
    container_port   = 3001
  }

  depends_on = [aws_lb_listener.http, aws_ecs_cluster_capacity_providers.main]

  tags = { Environment = var.environment }
}

resource "aws_ecs_service" "user_location_service" {
  name            = "user-location-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_location_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_location_service.arn
    container_name   = "user-location-service"
    container_port   = 3004
  }

  depends_on = [aws_lb_listener.http, aws_ecs_cluster_capacity_providers.main]

  tags = { Environment = var.environment }
}

resource "aws_ecs_service" "statistics_service" {
  name            = "statistics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.statistics_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.statistics_service.arn
    container_name   = "statistics-service"
    container_port   = 3005
  }

  depends_on = [aws_lb_listener.http, aws_ecs_cluster_capacity_providers.main]

  tags = { Environment = var.environment }
}

resource "aws_ecs_service" "authorities_service" {
  name            = "authorities-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.authorities_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.authorities_service.arn
    container_name   = "authorities-service"
    container_port   = 3006
  }

  depends_on = [aws_lb_listener.http, aws_ecs_cluster_capacity_providers.main]

  tags = { Environment = var.environment }
}
