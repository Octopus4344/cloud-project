output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "service_load_balancer_dns" {
  description = "The DNS names of each service's load balancer"
  value       = module.ecs.service_load_balancer_dns
}

output "service_load_balancer_urls" {
  description = "HTTP URLs for each service"
  value       = module.ecs.service_load_balancer_urls
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "Names of the ECS services"
  value       = module.ecs.service_names
}

output "alb_dns_name" {
  description = "Main ALB DNS Name"
  value       = lookup(module.ecs.service_load_balancer_dns, "authorities-service", "")
}

output "ecr_authorities_service_repository_url" {
  description = "URL of the Authorities Service ECR Repository"
  value       = lookup(module.ecs.ecr_repository_urls, "authorities-service", "")
}

output "ecr_road_event_service_repository_url" {
  description = "URL of the Road Event Service ECR Repository"
  value       = lookup(module.ecs.ecr_repository_urls, "road-event-service", "")
}

output "ecr_statistics_service_repository_url" {
  description = "URL of the Statistics Service ECR Repository"
  value       = lookup(module.ecs.ecr_repository_urls, "satistics-service", "")
}

output "ecr_user_data_service_repository_url" {
  description = "URL of the User Data Service ECR Repository"
  value       = lookup(module.ecs.ecr_repository_urls, "user-data-service", "")
}

output "ecr_user_location_service_repository_url" {
  description = "URL of the User Location Service ECR Repository"
  value       = lookup(module.ecs.ecr_repository_urls, "user-location-service", "")
}

