variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "incident-api"
}