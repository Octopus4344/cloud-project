provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "microservices-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "microservices-public-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 101}.0/24"
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  
  tags = {
    Name        = "microservices-private-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "microservices-igw"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name        = "microservices-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name        = "microservices-nat"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "microservices-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name        = "microservices-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "ecs_tasks" {
  name        = "microservices-ecs-tasks-sg"
  description = "Allow inbound access from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3010
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB to container ports"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "microservices-ecs-tasks-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name        = "microservices-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "microservices-alb-sg"
    Environment = var.environment
  }
}

resource "aws_ecs_cluster" "main" {
  name = "microservices-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Environment = var.environment
  }
}

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

locals {
  ecs_task_execution_role_arn = "arn:aws:iam::810315892481:role/LabRole"
}

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

resource "aws_lb" "main" {
  name               = "microservices-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Environment = var.environment
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "authorities_service" {
  name        = "authorities-service-tg"
  port        = 3006
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "road_event_service" {
  name        = "road-event-service-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "statistics_service" {
  name        = "statistics-service-tg"
  port        = 3005
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "user_data_service" {
  name        = "user-data-service-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "user_location_service" {
  name        = "user-location-service-tg"
  port        = 3004
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to Microservices API"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "authorities_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.authorities_service.arn
  }

  condition {
    path_pattern {
      values = ["/authorities*"]
    }
  }
}

resource "aws_lb_listener_rule" "road_event_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.road_event_service.arn
  }

  condition {
    path_pattern {
      values = ["/road-events*"]
    }
  }
}

resource "aws_lb_listener_rule" "statistics_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.statistics_service.arn
  }

  condition {
    path_pattern {
      values = ["/statistics*"]
    }
  }
}

resource "aws_lb_listener_rule" "user_data_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_data_service.arn
  }

  condition {
    path_pattern {
      values = ["/user-data*"]
    }
  }
}

resource "aws_lb_listener_rule" "user_location_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_location_service.arn
  }

  condition {
    path_pattern {
      values = ["/user-location*"]
    }
  }
}

resource "aws_ecs_task_definition" "authorities_service" {
  family                   = "authorities-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name        = "authorities-service",
    image       = "${aws_ecr_repository.authorities_service.repository_url}:latest",
    essential   = true,
    
    portMappings = [{
      containerPort = 3006,
      hostPort      = 3006
    }],
    
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "DATABASE_URL", value = var.supabase_db_url },
      { name = "RABBITMQ_URL", value = var.rabbitmq_url }
    ],
    
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.authorities_service.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "road_event_service" {
  family                   = "road-event-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name        = "road-event-service",
    image       = "${aws_ecr_repository.road_event_service.repository_url}:latest",
    essential   = true,
    
    portMappings = [{
      containerPort = 3000,
      hostPort      = 3000
    }],
    
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "DATABASE_URL", value = var.supabase_db_url },
      { name = "RABBITMQ_URL", value = var.rabbitmq_url }
    ],
    
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.road_event_service.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "statistics_service" {
  family                   = "statistics-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name        = "statistics-service",
    image       = "${aws_ecr_repository.statistics_service.repository_url}:latest",
    essential   = true,
    
    portMappings = [{
      containerPort = 3005,
      hostPort      = 3005
    }],
    
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "DATABASE_URL", value = var.supabase_db_url },
      { name = "RABBITMQ_URL", value = var.rabbitmq_url }
    ],
    
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.statistics_service.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "user_data_service" {
  family                   = "user-data-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name        = "user-data-service",
    image       = "${aws_ecr_repository.user_data_service.repository_url}:latest",
    essential   = true,
    
    portMappings = [{
      containerPort = 3001,
      hostPort      = 3001
    }],
    
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "DATABASE_URL", value = var.supabase_db_url },
      { name = "RABBITMQ_URL", value = var.rabbitmq_url }
    ],
    
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.user_data_service.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "user_location_service" {
  family                   = "user-location-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = local.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name        = "user-location-service",
    image       = "${aws_ecr_repository.user_location_service.repository_url}:latest",
    essential   = true,
    
    portMappings = [{
      containerPort = 3004,
      hostPort      = 3004
    }],
    
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "DATABASE_URL", value = var.supabase_db_url },
      { name = "RABBITMQ_URL", value = var.rabbitmq_url }
    ],
    
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = aws_cloudwatch_log_group.user_location_service.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "authorities_service" {
  name            = "authorities-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.authorities_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "road_event_service" {
  name            = "road-event-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.road_event_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "statistics_service" {
  name            = "statistics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.statistics_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "user_data_service" {
  name            = "user-data-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_data_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "user_location_service" {
  name            = "user-location-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_location_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = var.environment
  }
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the load balancer"
}

output "authorities_service_url" {
  value = "http://${aws_lb.main.dns_name}/authorities"
}

output "road_event_service_url" {
  value = "http://${aws_lb.main.dns_name}/road-events"
}

output "statistics_service_url" {
  value = "http://${aws_lb.main.dns_name}/statistics"
}

output "user_data_service_url" {
  value = "http://${aws_lb.main.dns_name}/user-data"
}

output "user_location_service_url" {
  value = "http://${aws_lb.main.dns_name}/user-location"
}

output "ecr_authorities_service_repository_url" {
  value = aws_ecr_repository.authorities_service.repository_url
}

output "ecr_road_event_service_repository_url" {
  value = aws_ecr_repository.road_event_service.repository_url
}

output "ecr_statistics_service_repository_url" {
  value = aws_ecr_repository.statistics_service.repository_url
}

output "ecr_user_data_service_repository_url" {
  value = aws_ecr_repository.user_data_service.repository_url
}

output "ecr_user_location_service_repository_url" {
  value = aws_ecr_repository.user_location_service.repository_url
}