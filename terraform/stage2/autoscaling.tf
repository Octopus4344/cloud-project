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
