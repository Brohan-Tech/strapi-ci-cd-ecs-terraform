provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_vpc" "default" {
  default = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "rohana_strapi_log_group" {
  name              = "/ecs/strapi-app"
  retention_in_days = 7
}

# Security group for ALB and ECS tasks
resource "aws_security_group" "rohana_sg" {
  name        = "rohana-sg"
  description = "Allow HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rohana-sg"
  }
}

# ALB
resource "aws_lb" "rohana_strapi_alb" {
  name               = "rohana-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rohana_sg.id]
  subnets            = ["subnet-0c0bb5df2571165a9", "subnet-0cc2ddb32492bcc41"]

  tags = {
    Name = "rohana-strapi-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "rohana_strapi_tg" {
  name         = "rohana-strapi-tg"
  port         = 1337
  protocol     = "HTTP"
  vpc_id       = data.aws_vpc.default.id
  target_type  = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "rohana-strapi-tg"
  }
}

# Listener
resource "aws_lb_listener" "rohana_listener" {
  load_balancer_arn = aws_lb.rohana_strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "rohana_strapi_cluster" {
  name = "rohana-strapi-cluster"
}

# Task Definition
resource "aws_ecs_task_definition" "rohana_strapi_task" {
  family                   = "rohana-strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "rohana-strapi"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
      environment = [
        { name = "APP_KEYS",          value = var.app_keys },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "JWT_SECRET",        value = var.jwt_secret },
        { name = "API_TOKEN_SALT",    value = var.api_token_salt }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.rohana_strapi_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "rohana-strapi"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "rohana_strapi_service" {
  name            = "rohana-strapi-service"
  cluster         = aws_ecs_cluster.rohana_strapi_cluster.id
  task_definition = aws_ecs_task_definition.rohana_strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0c0bb5df2571165a9", "subnet-0cc2ddb32492bcc41"]
    assign_public_ip = true
    security_groups  = [aws_security_group.rohana_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
    container_name   = "rohana-strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.rohana_listener]
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "rohana_cpu_high" {
  alarm_name          = "rohana-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Rohana Strapi task CPU usage high"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rohana_memory_high" {
  alarm_name          = "rohana-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Rohana Strapi task memory usage high"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rohana_unhealthy_tasks" {
  alarm_name          = "rohana-unhealthy-tasks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Rohana Strapi has unhealthy targets"
  dimensions = {
    TargetGroup = aws_lb_target_group.rohana_strapi_tg.arn_suffix
    LoadBalancer = aws_lb.rohana_strapi_alb.arn_suffix
  }
}

resource "aws_cloudwatch_dashboard" "rohana_dashboard" {
  dashboard_name = "rohana-strapi-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          title = "CPU Utilization"
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name]]
          period = 60
          stat = "Average"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 12
        height = 6
        properties = {
          title = "Memory Utilization"
          metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name]]
          period = 60
          stat = "Average"
        }
      }
    ]
  })
}

