environment = "prod"
aws_region  = "ap-northeast-1"

# Network configuration
vpc_cidr = "10.1.0.0/16"

# ECS configuration
ecs_cpu    = "512"
ecs_memory = "1024"

# Application configuration
container_port  = 8080
allowed_origins = "https://shisha-log.com,https://www.shisha-log.com"
token_duration  = "24h"

# Container image (update with your ECR repository)
container_image = "YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/shisha-log:latest"

# Sensitive variables - set these via environment variables
# export TF_VAR_supabase_url="your-supabase-url"
# export TF_VAR_supabase_anon_key="your-supabase-anon-key"
# export TF_VAR_supabase_service_role_key="your-supabase-service-role-key"
# export TF_VAR_jwt_secret="your-jwt-secret"
# export TF_VAR_database_url="your-database-url"domain_name = "api.shisha.toof.jp"
