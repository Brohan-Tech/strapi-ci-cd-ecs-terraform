output "rohana_alb_dns_name" {
  value = aws_lb.rohana_alb.dns_name
  description = "DNS name of the ALB"
}

output "rohana_log_group_name" {
  value = aws_cloudwatch_log_group.rohana_strapi_log_group.name
  description = "CloudWatch log group name"
}

output "rohana_dashboard_url" {
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=rohana-strapi-dashboard"
  description = "CloudWatch dashboard URL"
}

output "rohana_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.rohana_high_cpu_alarm.alarm_name
  description = "Name of the high CPU alarm"
}

output "rohana_memory_alarm_name" {
  value = aws_cloudwatch_metric_alarm.rohana_high_memory_alarm.alarm_name
  description = "Name of the high memory alarm"
}

