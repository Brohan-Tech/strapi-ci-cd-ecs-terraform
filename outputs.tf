output "strapi_url" {
  description = "Public URL of the deployed Strapi application"
  value       = "http://${aws_lb.rohana-strapi-alb.dns_name}"
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.rohana-strapi-service.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.rohana-strapi-cluster.name
}

output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.rohana-strapi-alb.dns_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.rohana-strapi-logs.name
}

