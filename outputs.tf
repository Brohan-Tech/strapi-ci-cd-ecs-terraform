output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.rohana-strapi-alb.dns_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.rohana-strapi-logs.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${var.AWS_REGION}#dashboards:name=rohana-strapi-dashboard"
}

output "cpu_alarm_name" {
  description = "CloudWatch alarm name for high CPU usage"
  value       = aws_cloudwatch_metric_alarm.rohana-high-cpu-alarm.name
}

output "memory_alarm_name" {
  description = "CloudWatch alarm name for high memory usage"
  value       = aws_cloudwatch_metric_alarm.rohana-high-memory-alarm.name
}

