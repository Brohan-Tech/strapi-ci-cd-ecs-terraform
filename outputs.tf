output "strapi_url" {
  description = "Public URL of the Strapi application"
  value       = aws_lb.rohana_strapi_alb.dns_name
}

output "task_definition_arn" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.rohana_strapi_task.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.rohana_strapi_service.name
}

