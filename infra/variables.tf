variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "shisha-log"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "ecs_cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "Memory for the ECS task"
  type        = string
  default     = "512"
}

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for token validation"
  type        = string
  sensitive   = true
}

variable "allowed_origins" {
  description = "Comma-separated list of allowed CORS origins"
  type        = string
  default     = "*"
}

variable "database_url" {
  description = "Direct database connection URL"
  type        = string
  sensitive   = true
}

variable "token_duration" {
  description = "JWT token expiration duration"
  type        = string
  default     = "24h"
}

variable "domain_name" {
  description = "Domain name for SSL certificate (e.g., api.example.com)"
  type        = string
}