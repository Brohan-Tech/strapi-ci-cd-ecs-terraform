variable "image" {
  description = "The Docker image to use for the Strapi container"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task role"
  type        = string
}

