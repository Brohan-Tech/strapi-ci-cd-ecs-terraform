variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "container_image" {
  description = "ECR container image URI"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS Task Role ARN"
  type        = string
}

variable "app_keys" {
  description = "APP_KEYS secret for Strapi"
  type        = string
}

variable "jwt_secret" {
  description = "JWT_SECRET for Strapi"
  type        = string
}

variable "admin_jwt_secret" {
  description = "ADMIN_JWT_SECRET for Strapi"
  type        = string
}

variable "api_token_salt" {
  description = "API_TOKEN_SALT for Strapi"
  type        = string
}

