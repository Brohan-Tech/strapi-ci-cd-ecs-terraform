output "strapi_url" {
  description = "Public URL of the Strapi ALB"
  value       = "http://${aws_lb.strapi.dns_name}:1337"
}

output "task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.strapi.arn
}

output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.strapi.name
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.strapi.name
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.strapi.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.strapi.dns_name
}

output "cpu_alarm_arn" {
  description = "ARN of the CPU Utilization CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "memory_alarm_arn" {
  description = "ARN of the Memory Utilization CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.memory_high.arn
}

output "dashboard_url" {
  description = "URL to view the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.strapi.dashboard_name}"
}

