variable "aws_region" {
  description = "Region AWS, w którym zostanie wdrożona infrastruktura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Środowisko (np. dev, prod)"
  type        = string
  default     = "dev"
}

variable "supabase_db_url" {
  description = "URL połączenia do bazy danych Supabase"
  type        = string
  sensitive   = true
}

variable "rabbitmq_url" {
  description = "URL połączenia do serwera RabbitMQ"
  type        = string
  sensitive   = true
}