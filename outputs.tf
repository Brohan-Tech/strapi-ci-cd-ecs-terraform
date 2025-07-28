output "strapi_url" {
  description = "Public URL of the Strapi application"
  value       = aws_lb.rohana_strapi_alb.dns_name
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.strapi_log_group.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=rohana-strapi-dashboard"
}

output "cpu_alarm_name" {
  description = "High CPU usage alarm name"
  value       = aws_cloudwatch_metric_alarm.rohana_high_cpu_alarm.name
}

output "memory_alarm_name" {
  description = "High memory usage alarm name"
  value       = aws_cloudwatch_metric_alarm.rohana_high_memory_alarm.name
}

