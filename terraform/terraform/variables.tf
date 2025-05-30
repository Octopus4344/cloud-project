variable "aws_region" {
  description = ""
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = ""
  type        = string
  default     = "dev"
}

variable "supabase_db_url" {
  description = ""
  type        = string
  sensitive   = true
}

variable "rabbitmq_url" {
  description = ""
  type        = string
  sensitive   = true
}
