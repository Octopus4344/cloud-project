provider "aws" {
  region = var.aws_region
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

data "archive_file" "lambda_archive_func" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/archive-road-event"
  output_path = "${path.module}/lambda/archive-road-event.zip"
}

# ============================================================
# NETWORKING
# ============================================================

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

# ============================================================
# SECURITY GROUPS
# ============================================================

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

resource "aws_security_group" "ecs_instances" {
  name        = "microservices-ecs-instances-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = [aws_security_group.alb.id]
    description     = "Allow ALB to reach containers on dynamic ports"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "microservices-ecs-instances-sg"
    Environment = var.environment
  }
}

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

# ============================================================
# COGNITO USER POOL
# ============================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-road-events-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.environment}-road-events-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
}

# ============================================================
# DYNAMODB TABLES
# ============================================================

resource "aws_dynamodb_table" "road_events" {
  name         = "${var.environment}-road-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "event_status" {
  name         = "${var.environment}-event-status"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "users" {
  name         = "${var.environment}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "locations" {
  name         = "${var.environment}-locations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "statistics" {
  name         = "${var.environment}-statistics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "statId"

  attribute {
    name = "statId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "incidents" {
  name         = "${var.environment}-incidents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incidentId"

  attribute {
    name = "incidentId"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

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

# Allow SNS to send to SQS queues
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

# SNS → SQS subscriptions (fan-out on completed events)
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

# ============================================================
# S3 – ROAD EVENTS ARCHIVE BUCKET
# ============================================================

resource "aws_s3_bucket" "road_events_archive" {
  bucket        = "${var.environment}-events-archive-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "road_events_archive" {
  bucket = aws_s3_bucket.road_events_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "road_events_archive" {
  bucket = aws_s3_bucket.road_events_archive.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "road_events_archive" {
  bucket                  = aws_s3_bucket.road_events_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# LAMBDA – ARCHIVE ROAD EVENTS TO S3
# ============================================================

resource "aws_lambda_function" "archive_road_event" {
  filename         = data.archive_file.lambda_archive_func.output_path
  source_code_hash = data.archive_file.lambda_archive_func.output_base64sha256
  function_name    = "${var.environment}-archive-road-event"
  role             = aws_iam_role.lambda_archive.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      AWS_ACCOUNT_REGION = var.aws_region
      ARCHIVE_BUCKET     = aws_s3_bucket.road_events_archive.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_archive]

  tags = {
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "archive_sqs" {
  event_source_arn                   = aws_sqs_queue.archive.arn
  function_name                      = aws_lambda_function.archive_road_event.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true
}

# ============================================================
# ============================================================
# IAM ROLES
# ============================================================

# EC2 instance role – grants ECS agent on the host the right to
# register with the cluster and pull task metadata
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.environment}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ec2_service" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.environment}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# ECS task execution role – pull ECR images, write CloudWatch logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS task role – runtime access to SQS, SNS, DynamoDB, Cognito
resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_permissions" {
  name = "${var.environment}-ecs-task-permissions"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage",
          "sqs:GetQueueAttributes", "sqs:GetQueueUrl"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.road_events_completed.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Scan", "dynamodb:Query"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminSetUserPassword"
        ]
        Resource = aws_cognito_user_pool.main.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

# Lambda execution role – read SQS archive queue, write to S3
resource "aws_iam_role" "lambda_archive" {
  name = "${var.environment}-lambda-archive-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_archive_permissions" {
  name = "${var.environment}-lambda-archive-permissions"
  role = aws_iam_role.lambda_archive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.archive.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectAcl"]
        Resource = "${aws_s3_bucket.road_events_archive.arn}/*"
      }
    ]
  })
}

locals {
  ecs_task_execution_role_arn = aws_iam_role.ecs_task_execution.arn
  ecs_task_role_arn           = aws_iam_role.ecs_task.arn
}

# ============================================================
# ECS – EC2 CLUSTER WITH AUTO SCALING
# ============================================================

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-launch-template-${var.environment}-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_instances.id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=microservices-cluster >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ecs-instance-${var.environment}"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-asg-${var.environment}"
  vpc_zone_identifier       = aws_subnet.private[*].id
  min_size                  = 2
  max_size                  = 8
  desired_capacity          = 2
  wait_for_capacity_timeout = "0"

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  protect_from_scale_in = true

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "ec2-capacity-provider-${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
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

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

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

  tags = { Environment = var.environment }
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

  tags = { Environment = var.environment }
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

  tags = { Environment = var.environment }
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

  tags = { Environment = var.environment }
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

  tags = { Environment = var.environment }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to Road Events Microservices API"
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
    path_pattern { values = ["/authorities*"] }
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
    path_pattern { values = ["/road-events*"] }
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
    path_pattern { values = ["/statistics*"] }
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
    path_pattern { values = ["/user-data*"] }
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
    path_pattern { values = ["/user-location*"] }
  }
}

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
    image     = "${aws_ecr_repository.road_event_service.repository_url}:latest"
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
        "awslogs-group"         = aws_cloudwatch_log_group.road_event_service.name
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
    image     = "${aws_ecr_repository.user_data_service.repository_url}:latest"
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
        "awslogs-group"         = aws_cloudwatch_log_group.user_data_service.name
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
    image     = "${aws_ecr_repository.user_location_service.repository_url}:latest"
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
        "awslogs-group"         = aws_cloudwatch_log_group.user_location_service.name
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
    image     = "${aws_ecr_repository.statistics_service.repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3005, hostPort = 3005 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_STATISTICS_QUEUE_URL", value = aws_sqs_queue.statistics.url },
      { name = "DYNAMODB_STATISTICS_TABLE", value = aws_dynamodb_table.statistics.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.statistics_service.name
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
    image     = "${aws_ecr_repository.authorities_service.repository_url}:latest"
    essential = true

    portMappings = [{ containerPort = 3006, hostPort = 3006 }]

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SQS_AUTHORITIES_QUEUE_URL", value = aws_sqs_queue.authorities.url },
      { name = "SNS_ROAD_EVENTS_COMPLETED_ARN", value = aws_sns_topic.road_events_completed.arn },
      { name = "DYNAMODB_INCIDENTS_TABLE", value = aws_dynamodb_table.incidents.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.authorities_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Environment = var.environment }
}

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

# ============================================================
# ECS SERVICE AUTO SCALING
# ============================================================

locals {
  services_autoscaling = {
    road_event  = { service = "road-event-service",  min = 1, max = 5 }
    user_data   = { service = "user-data-service",   min = 1, max = 4 }
    user_loc    = { service = "user-location-service", min = 1, max = 4 }
    statistics  = { service = "statistics-service",  min = 1, max = 6 }
    authorities = { service = "authorities-service", min = 1, max = 4 }
  }
}

resource "aws_appautoscaling_target" "ecs_services" {
  for_each           = local.services_autoscaling
  max_capacity       = each.value.max
  min_capacity       = each.value.min
  resource_id        = "service/${aws_ecs_cluster.main.name}/${each.value.service}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [
    aws_ecs_service.road_event_service,
    aws_ecs_service.user_data_service,
    aws_ecs_service.user_location_service,
    aws_ecs_service.statistics_service,
    aws_ecs_service.authorities_service,
  ]
}

resource "aws_appautoscaling_policy" "ecs_cpu_scale_out" {
  for_each           = local.services_autoscaling
  name               = "${each.value.service}-cpu-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_memory_scale_out" {
  for_each           = local.services_autoscaling
  name               = "${each.value.service}-memory-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 80.0
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

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
