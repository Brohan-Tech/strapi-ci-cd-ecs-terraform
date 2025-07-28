output "strapi_url" {
  value       = "http://${aws_lb.rohana_strapi_alb.dns_name}"
  description = "Public URL of the deployed Strapi application"
}

output "ecs_service_name" {
  value       = aws_ecs_service.rohana_strapi_service.name
  description = "ECS service name"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.rohana_strapi_cluster.name
  description = "ECS cluster name"
}

output "alb_dns" {
  value       = aws_lb.rohana_strapi_alb.dns_name
  description = "ALB DNS name"
}

output "cloudwatch_log_group" {
  value       = aws_cloudwatch_log_group.rohana_strapi_logs.name
  description = "CloudWatch log group name"
}
