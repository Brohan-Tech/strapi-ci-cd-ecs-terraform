variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "execution_role_arn" {
  description = "IAM Role ARN for ECS task execution"
  type        = string
}

variable "task_role_arn" {
  description = "IAM Role ARN for the ECS task"
  type        = string
}

variable "container_image" {
  description = "Docker image URI for Strapi"
  type        = string
}

variable "app_keys" {
  description = "Strapi APP_KEYS"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "Strapi API_TOKEN_SALT"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Strapi JWT_SECRET"
  type        = string
  sensitive   = true
}

