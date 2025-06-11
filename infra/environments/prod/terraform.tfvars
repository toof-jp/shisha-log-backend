environment = "prod"
aws_region  = "ap-northeast-1"

# Lightsail configuration
availability_zone = "ap-northeast-1a"
bundle_id        = "small_2_0"  # $10/month for production

# Domain configuration
domain_name = "api.shisha.toof.jp"

# Container registry configuration (AWS ECR Public)
container_registry = "public.ecr.aws"
container_image    = "571600847070/shisha-log:latest"  # Replace YOUR_ECR_ALIAS with actual alias

# Application configuration
allowed_origins = "https://shisha.toof.jp,https://www.shisha.toof.jp"
token_duration  = "24h"

# Sensitive variables - set these via environment variables:
# export TF_VAR_supabase_url="your-supabase-url"
# export TF_VAR_supabase_anon_key="your-supabase-anon-key"
# export TF_VAR_supabase_service_role_key="your-supabase-service-role-key"
# export TF_VAR_jwt_secret="your-jwt-secret"
# export TF_VAR_database_url="your-database-url"
# export TF_VAR_registry_username="your-registry-username"
# export TF_VAR_registry_password="your-registry-password"

