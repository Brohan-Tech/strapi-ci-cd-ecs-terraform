variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-2"
}

variable "container_image" {
  description = "Docker image URI for Strapi"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for ECS execution"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN for ECS task"
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

