provider "aws" {
  region = var.aws_region
}

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

data "aws_caller_identity" "current" {}
