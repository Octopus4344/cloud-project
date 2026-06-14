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

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB to frontend port"
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
