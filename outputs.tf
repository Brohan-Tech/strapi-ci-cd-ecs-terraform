output "strapi_url" {
  description = "Public URL to access Strapi"
  value       = "http://${aws_lb.strapi.dns_name}:1337"
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.strapi.name
}

output "cluster_name" {
  value = aws_ecs_cluster.strapi.name
}

output "service_name" {
  value = aws_ecs_service.strapi.name
}

output "cpu_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "memory_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.memory_high.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.strapi.dashboard_name
}

