output "alb_dns_name" {
  description = "ALB DNS name to access Strapi"
  value       = aws_lb.strapi.dns_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group Name for ECS Logs"
  value       = aws_cloudwatch_log_group.strapi.name
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=rohana-strapi-dashboard"
}

output "cpu_alarm_name" {
  description = "CloudWatch CPU alarm name"
  value       = aws_cloudwatch_metric_alarm.cpu_high.name
}

output "memory_alarm_name" {
  description = "CloudWatch Memory alarm name"
  value       = aws_cloudwatch_metric_alarm.memory_high.name
}

