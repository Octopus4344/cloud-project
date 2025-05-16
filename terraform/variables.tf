variable "aws_region" {
  description = "AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-project"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "rabbitmq_url" {
  description = "Connection string for the existing RabbitMQ server"
  type        = string
  sensitive   = true
  default     = "amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "supabase_db_url" {
  description = "Connection string for Supabase database"
  type        = string
  sensitive   = true
  default     = "postgresql://postgres.sfbspjuexczprymnpoer:postgres@aws-0-eu-central-2.pooler.supabase.com:5432/postgres"
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
      database_url   = "postgresql://postgres:postgres@localhost:5432/authorities_service_db"
    },
    "road-event-service" = {
      container_port = 3000
      host_port      = 3000
      cpu            = 256
      memory         = 512
      image          = "road-event-service:latest"
      database_url   = "postgresql://postgres:postgres@localhost:5432/road_event_service_db"
    },
    "satistics-service" = {
      container_port = 3005
      host_port      = 3005
      cpu            = 256
      memory         = 512
      image          = "satistics-service:latest"
      database_url   = "postgresql://postgres:postgres@localhost:5432/satistics_service_db"
    },
    "user-data-service" = {
      container_port = 3001
      host_port      = 3001
      cpu            = 256
      memory         = 512
      image          = "user-data-service:latest"
      database_url   = "postgresql://postgres:postgres@localhost:5432/user_data_service_db"
    },
    "user-location-service" = {
      container_port = 3004
      host_port      = 3004
      cpu            = 256
      memory         = 512
      image          = "user-location-service:latest"
      database_url   = "postgresql://postgres:postgres@localhost:5432/user_location_service_db"
    }
  }
}
