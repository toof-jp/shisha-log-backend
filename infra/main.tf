terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "lightsail" {
  source = "./modules/lightsail"
  
  project_name    = var.project_name
  environment     = var.environment
  availability_zone = var.availability_zone
  bundle_id       = var.bundle_id
  domain_name     = var.domain_name
  
  # Container registry configuration
  container_registry = var.container_registry
  container_image    = var.container_image
  registry_username  = var.registry_username
  registry_password  = var.registry_password
  
  # Application configuration
  supabase_url              = var.supabase_url
  supabase_anon_key         = var.supabase_anon_key
  supabase_service_role_key = var.supabase_service_role_key
  jwt_secret                = var.jwt_secret
  database_url              = var.database_url
  allowed_origins           = var.allowed_origins
  token_duration            = var.token_duration
}

