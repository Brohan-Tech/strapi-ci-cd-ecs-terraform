provider "aws" {
  region = "us-east-2"
}

resource "aws_ecs_cluster" "rohana_strapi_cluster" {
  name = "rohana-strapi-cluster"
}

resource "aws_cloudwatch_log_group" "rohana_strapi_log_group" {
  name              = "/ecs/rohana-strapi"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "rohana_strapi_task" {
  family                   = "rohana-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "rohana-strapi"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/rohana-strapi-repo:latest"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
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
          awslogs-region        = "us-east-2"
          awslogs-stream-prefix = "ecs/rohana-strapi"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "rohana_strapi_service" {
  name            = "rohana-strapi-service"
  cluster         = aws_ecs_cluster.rohana_strapi_cluster.id
  task_definition = aws_ecs_task_definition.rohana_strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-0a1e6640cafebb652", "subnet-0f768008c6324831f"]
    security_groups = [aws_security_group.rohana_strapi_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
    container_name   = "rohana-strapi"
    container_port   = 1337
  }
  depends_on = [aws_lb_listener.rohana_strapi_listener]
}

resource "aws_security_group" "rohana_strapi_sg" {
  name        = "rohana-strapi-sg"
  description = "Allow HTTP"
  vpc_id      = "vpc-06ba36bca6b59f95e"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "rohana_strapi_alb" {
  name               = "rohana-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rohana_strapi_sg.id]
  subnets            = ["subnet-0a1e6640cafebb652", "subnet-0f768008c6324831f"]
}

resource "aws_lb_target_group" "rohana_strapi_tg" {
  name     = "rohana-strapi-tg"
  port     = 1337
  protocol = "HTTP"
  vpc_id   = "vpc-06ba36bca6b59f95e"
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "rohana_strapi_listener" {
  load_balancer_arn = aws_lb.rohana_strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when CPU exceeds 80%"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization_alarm" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when memory exceeds 80%"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }
}

resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "rohana-StrapiDashboard"

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
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name ],
            [ "AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.rohana_strapi_cluster.name, "ServiceName", aws_ecs_service.rohana_strapi_service.name ]
          ],
          view = "timeSeries",
          stacked = false,
          region = "us-east-2",
          title = "ECS Service Metrics"
        }
      }
    ]
  })
}

