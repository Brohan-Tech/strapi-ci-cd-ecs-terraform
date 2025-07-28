provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_cloudwatch_log_group" "rohana-strapi-log-group" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "rohana-strapi-cluster" {
  name = "rohana-strapi-cluster"
}

resource "aws_lb" "rohana-strapi-alb" {
  name               = "rohana-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids

  tags = {
    Name = "rohana-strapi-alb"
  }
}

resource "aws_lb_target_group" "rohana-strapi-tg" {
  name        = "rohana-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/_health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "rohana-strapi-listener" {
  load_balancer_arn = aws_lb.rohana-strapi-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rohana-strapi-tg.arn
  }
}

resource "aws_ecs_task_definition" "rohana-strapi-task" {
  family                   = "rohana-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
      environment = [
        { name = "APP_KEYS", value = var.app_keys },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "API_TOKEN_SALT", value = var.api_token_salt }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.rohana-strapi-log-group.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs/strapi"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "rohana-strapi-service" {
  name            = "rohana-strapi-service"
  cluster         = aws_ecs_cluster.rohana-strapi-cluster.id
  task_definition = aws_ecs_task_definition.rohana-strapi-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    assign_public_ip = true
    security_groups  = []
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rohana-strapi-tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.rohana-strapi-listener]
}

resource "aws_cloudwatch_metric_alarm" "rohana-high-cpu-alarm" {
  alarm_name          = "HighCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm triggers if CPU > 80% for 2 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana-strapi-cluster.name
    ServiceName = aws_ecs_service.rohana-strapi-service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rohana-high-memory-alarm" {
  alarm_name          = "HighMemoryUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm triggers if memory > 80% for 2 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana-strapi-cluster.name
    ServiceName = aws_ecs_service.rohana-strapi-service.name
  }
}

resource "aws_cloudwatch_dashboard" "rohana-strapi-dashboard" {
  dashboard_name = "rohana-strapi-dashboard"
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
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.rohana-strapi-cluster.name, "ServiceName", aws_ecs_service.rohana-strapi-service.name ],
            [ ".", "MemoryUtilization", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "ECS Cluster CPU & Memory Usage"
        }
      }
    ]
  })
}

