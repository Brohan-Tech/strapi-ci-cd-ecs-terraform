provider "aws" {
  region = var.aws_region
}

# VPC 
resource "aws_vpc" "rohana_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "rohana-vpc"
  }
}

resource "aws_internet_gateway" "rohana_igw" {
  vpc_id = aws_vpc.rohana_vpc.id

  tags = {
    Name = "rohana-igw"
  }
}

resource "aws_subnet" "rohana_public_a" {
  vpc_id                  = aws_vpc.rohana_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "rohana-public-subnet-a"
  }
}

resource "aws_subnet" "rohana_public_b" {
  vpc_id                  = aws_vpc.rohana_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "rohana-public-subnet-b"
  }
}

resource "aws_route_table" "rohana_public_rt" {
  vpc_id = aws_vpc.rohana_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rohana_igw.id
  }

  tags = {
    Name = "rohana-public-rt"
  }
}

resource "aws_route_table_association" "rohana_assoc_a" {
  subnet_id      = aws_subnet.rohana_public_a.id
  route_table_id = aws_route_table.rohana_public_rt.id
}

resource "aws_route_table_association" "rohana_assoc_b" {
  subnet_id      = aws_subnet.rohana_public_b.id
  route_table_id = aws_route_table.rohana_public_rt.id
}

# ECS & Networking
resource "aws_ecs_cluster" "rohana_strapi_cluster" {
  name = "rohana-strapi-cluster"
}

resource "aws_cloudwatch_log_group" "rohana_strapi_logs" {
  name              = "/ecs/rohana-strapi"
  retention_in_days = 7
}

resource "aws_security_group" "rohana_alb_sg" {
  name   = "rohana-strapi-alb-sg"
  vpc_id = aws_vpc.rohana_vpc.id

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
}

resource "aws_lb" "rohana_strapi_alb" {
  name               = "rohana-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rohana_alb_sg.id]
  subnets            = [aws_subnet.rohana_public_a.id, aws_subnet.rohana_public_b.id]
}

resource "aws_lb_target_group" "rohana_strapi_tg" {
  name        = "rohana-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.rohana_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "rohana_http" {
  load_balancer_arn = aws_lb.rohana_strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
  }
}

resource "aws_ecs_task_definition" "rohana_strapi_task" {
  family                   = "rohana-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = var.container_image
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
    }]
    environment = [
      { name = "APP_KEYS", value = var.app_keys },
      { name = "API_TOKEN_SALT", value = var.api_token_salt },
      { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
      { name = "JWT_SECRET", value = var.jwt_secret }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.rohana_strapi_logs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "rohana_strapi_service" {
  name            = "rohana-strapi-service"
  cluster         = aws_ecs_cluster.rohana_strapi_cluster.id
  task_definition = aws_ecs_task_definition.rohana_strapi_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.rohana_public_a.id, aws_subnet.rohana_public_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.rohana_alb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rohana_strapi_tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  desired_count = 1
  depends_on    = [aws_lb_listener.rohana_http]
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alarm if CPU exceeds 75%"
  dimensions = {
    ClusterName = aws_ecs_cluster.rohana_strapi_cluster.name
    ServiceName = aws_ecs_service.rohana_strapi_service.name
  }
}
