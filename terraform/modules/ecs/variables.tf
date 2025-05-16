variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rabbitmq_url" {
  description = "Connection string for the existing RabbitMQ server"
  type        = string
  sensitive   = true
}

variable "services" {
  description = "Configuration for each microservice"
  type = map(object({
    container_port = number
    host_port      = number
    cpu            = number
    memory         = number
    image          = string
    database_url   = optional(string)
  }))
  default = {
    "authorities-service" = {
      container_port = 3006
      host_port      = 3006
      cpu            = 256
      memory         = 512
      image          = "authorities-service:latest"
    },
    "road-event-service" = {
      container_port = 3000
      host_port      = 3000
      cpu            = 256
      memory         = 512
      image          = "road-event-service:latest"
    },
    "satistics-service" = {
      container_port = 3005
      host_port      = 3005
      cpu            = 256
      memory         = 512
      image          = "satistics-service:latest"
    },
    "user-data-service" = {
      container_port = 3001
      host_port      = 3001
      cpu            = 256
      memory         = 512
      image          = "user-data-service:latest"
    },
    "user-location-service" = {
      container_port = 3004
      host_port      = 3004
      cpu            = 256
      memory         = 512
      image          = "user-location-service:latest"
    }
  }
}

variable "lb_security_group_id" {
  description = "The ID of the security group for the load balancer"
  type        = string
}

variable "ecs_tasks_security_group_id" {
  description = "The ID of the security group for ECS tasks"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role that the ECS service can use as an execution role"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "ARN of an existing IAM role that the ECS tasks can use"
  type        = string
  default     = ""
}
