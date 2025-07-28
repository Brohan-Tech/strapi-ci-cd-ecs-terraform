provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Data sources

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "strapi_log_group" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

# Security group for ALB and ECS tasks
resource "aws_security_group" "rohana_sg" {
  name        = "rohana-sg"
  description = "Allow HTTP and Strapi access"
  vpc_id      = data.aws_vpc.selected.id

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

# Load Balancer
resource "aws_lb" "rohana_strapi_alb" {
  name               = "rohana-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rohana_sg.id]
  subnets            = data.aws_subnets.selected.ids

  tags = {
    Name = "rohana-strapi-alb"
  }
}

resource "aws_lb_target_group" "rohana_strapi_tg" {
  name        = "rohana-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

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
          awslogs-group         = aws_cloudwatch_log_group.strapi_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs/strapi"
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
    subnets          = data.aws_subnets.selected.ids
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
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "rohana-strapi-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }

  alarm_description = "Alarm when CPU exceeds 70%"
  treat_missing_data = "missing"
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "rohana-strapi-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }

  alarm_description = "Alarm when memory exceeds 75%"
  treat_missing_data = "missing"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "StrapiMonitoringDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name]
          ],
          view = "timeSeries",
          stacked = false,
          region = var.region,
          title = "ECS Cluster Metrics"
        }
      }
    ]
  })
}

