variable "container_image" {
  description = "Docker image URI for the ECS task"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task"
  type        = string
}

variable "app_keys" {
  description = "Strapi app keys"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for Strapi"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "Admin JWT secret for Strapi"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "API token salt for Strapi"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
  default     = "vpc-0dfdf2a662bda32e0"
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
  default     = ["subnet-0a4a4b2ce473cdb14", "subnet-08d41418e6920632f"]
}

