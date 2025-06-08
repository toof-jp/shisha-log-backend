# Shisha Log Backend Infrastructure

This directory contains Terraform configurations to deploy the Shisha Log backend on AWS using ECS Fargate in a simplified, cost-effective architecture.

## Architecture Overview

- **VPC**: Custom VPC with single public subnet
- **ECS Fargate**: Single containerized backend instance with direct internet access
- **CloudWatch**: Logs and monitoring with Container Insights
- **Supabase**: External database (not managed by this Terraform)

This simplified architecture balances cost efficiency with observability, suitable for small applications with low traffic requirements.

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)
3. Docker image pushed to ECR
4. Supabase project set up

## Directory Structure

```
infra/
├── main.tf                    # Root module configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── modules/
│   ├── networking/           # VPC, single public subnet
│   └── ecs/                  # ECS cluster, service, task definition
└── environments/
    ├── dev/                  # Development environment config
    └── prod/                 # Production environment config
```

## Setup Instructions

### 1. Build and Push Docker Image to ECR

```bash
# Create ECR repository
aws ecr create-repository --repository-name shisha-log --region ap-northeast-1

# Get login token
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com

# Build and tag image
docker build -t shisha-log .
docker tag shisha-log:latest YOUR_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/shisha-log:latest

# Push image
docker push YOUR_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/shisha-log:latest
```

### 2. Set Environment Variables

Export sensitive variables:

```bash
export TF_VAR_supabase_url="https://your-project.supabase.co"
export TF_VAR_supabase_anon_key="your-anon-key"
export TF_VAR_supabase_service_role_key="your-service-role-key"
export TF_VAR_jwt_secret="your-jwt-secret"
export TF_VAR_database_url="postgresql://user:password@host:5432/database"
```

### 3. Update terraform.tfvars

Update the `container_image` variable in the environment-specific `terraform.tfvars` file with your ECR repository URL.

### 4. Deploy Infrastructure

For development:
```bash
cd infra
terraform init
terraform workspace new dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

For production:
```bash
cd infra
terraform workspace new prod
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Accessing the Application

Your application will be accessible directly through the ECS task's public IP address on port 8080. To find the IP address:

```bash
# Get task ARN
aws ecs list-tasks --cluster shisha-log-dev-cluster --service-name shisha-log-dev-service

# Get task details including public IP
aws ecs describe-tasks --cluster shisha-log-dev-cluster --tasks [TASK_ARN]
```

For production use, consider:
1. Setting up a domain name with Route53
2. Using CloudFront for CDN and SSL termination
3. Implementing proper health checks

## Outputs

After deployment, Terraform will output:
- `ecs_cluster_id`: ECS cluster identifier
- `ecs_service_name`: ECS service name
- `vpc_id`: VPC identifier
- `public_subnet_id`: Public subnet identifier

## Cost Optimization

This simplified architecture provides excellent cost efficiency:
- **No ALB**: Saves ~$22/month
- **No NAT Gateways**: Saves ~$90/month
- **Single AZ**: No cross-AZ data transfer costs
- **Single Task**: Minimal compute resources
- **ECS Fargate**: ~$15/month (256CPU, 512MB for dev)
- **CloudWatch**: ~$5/month (logs and metrics)

**Total monthly cost**: ~$20/month (vs ~$112/month with full HA setup)

Additional cost-saving tips:
- Use Fargate Spot for non-critical workloads (up to 70% savings)
- Use smaller instance sizes for development

## Monitoring

- **CloudWatch Logs**: `/ecs/shisha-log-{environment}` (30 days retention)
- **Container Insights**: ECS cluster and service metrics
- **ECS Service health checks**: Container restart on failure
- **Application logs**: Available in CloudWatch for debugging and monitoring

You can view logs using:
```bash
aws logs tail /ecs/shisha-log-dev --follow
```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file=environments/{environment}/terraform.tfvars
```