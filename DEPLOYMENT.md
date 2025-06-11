# Deployment Guide

This guide explains how to deploy the Shisha Log backend to AWS Lightsail using Terraform.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (>= 1.0)
3. **AWS CLI** installed and configured
4. **Docker** installed (for building images)
5. **Domain name** with DNS control

## Setup Steps

### 1. Environment Configuration

Create environment files from the example:

```bash
make setup-env
```

This creates `.env` and `.env.prod` files. Edit them with your actual values:

- **Supabase Configuration**: Get from your Supabase project settings
- **JWT Secret**: Generate a secure random string
- **Database URL**: Your Supabase PostgreSQL connection string
- **AWS Credentials**: Your AWS access keys
- **Domain**: Your actual domain names

### 2. ECR Public Repository Setup

Create an ECR Public repository for your Docker images:

```bash
make setup-ecr
```

This will:
- Create a public ECR repository named `shisha-log`
- Output the repository URI to use in terraform.tfvars files

### 3. Update Terraform Configuration

Edit the terraform.tfvars files with your ECR repository URI:

**For development** (`infra/environments/dev/terraform.tfvars`):
```hcl
container_image = "public.ecr.aws/YOUR_ECR_ALIAS/shisha-log:dev-latest"
domain_name = "api-dev.yourdomain.com"
```

**For production** (`infra/environments/prod/terraform.tfvars`):
```hcl
container_image = "public.ecr.aws/YOUR_ECR_ALIAS/shisha-log:latest"
domain_name = "api.yourdomain.com"
```

### 4. Build and Push Docker Image

```bash
# Build the image
make docker-build

# Set your ECR alias (from step 2)
export ECR_ALIAS=your_ecr_alias

# Push to ECR Public
make docker-push
```

For development, tag and push a dev version:
```bash
docker tag shisha-log:latest public.ecr.aws/$ECR_ALIAS/shisha-log:dev-latest
docker push public.ecr.aws/$ECR_ALIAS/shisha-log:dev-latest
```

## Deployment

### Development Environment

```bash
# Initialize Terraform (first time only)
make infra-init

# Plan the deployment
make infra-plan-dev

# Apply the infrastructure
make infra-apply-dev

# Check outputs
make infra-output-dev
```

### Production Environment

```bash
# Plan the deployment
make infra-plan-prod

# Apply the infrastructure
make infra-apply-prod

# Check outputs
make infra-output-prod
```

## DNS Configuration

After deployment, configure your domain DNS:

1. Get the static IP from Terraform output:
   ```bash
   make infra-output-dev  # or infra-output-prod
   ```

2. Create an A record pointing your domain to the static IP:
   ```
   A record: api-dev.yourdomain.com -> XXX.XXX.XXX.XXX
   A record: api.yourdomain.com -> XXX.XXX.XXX.XXX
   ```

3. Wait for DNS propagation (5-30 minutes)

## SSL Certificate

SSL certificates are automatically obtained using Let's Encrypt:

1. The system waits for DNS propagation
2. Automatically requests and installs SSL certificate
3. Sets up auto-renewal

Check SSL setup status:
```bash
# SSH into the instance
ssh ubuntu@YOUR_STATIC_IP

# Check SSL setup service
sudo journalctl -u setup-ssl.service

# Manually trigger SSL setup if needed
sudo /opt/shisha-log/setup-ssl.sh
```

## Updating the Application

1. Build and push new Docker image:
   ```bash
   make docker-build
   export ECR_ALIAS=your_ecr_alias
   make docker-push
   ```

2. SSH into the instance and restart the application:
   ```bash
   ssh ubuntu@YOUR_STATIC_IP
   sudo docker pull public.ecr.aws/YOUR_ECR_ALIAS/shisha-log:latest
   sudo systemctl restart shisha-log
   ```

## Monitoring and Logs

View application logs:
```bash
ssh ubuntu@YOUR_STATIC_IP
sudo journalctl -u shisha-log -f
```

View Nginx logs:
```bash
ssh ubuntu@YOUR_STATIC_IP
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Costs

- **Development**: ~$3.50/month (nano_2_0 instance)
- **Production**: ~$10/month (small_2_0 instance)
- **ECR Public**: Free (50GB storage included)
- **Data transfer**: Minimal cost for small applications

## Troubleshooting

### Common Issues

1. **DNS not propagating**: Wait longer, use `dig` to check
2. **SSL certificate fails**: Ensure DNS points to correct IP
3. **Application won't start**: Check environment variables in .env
4. **Docker pull fails**: Verify ECR repository URI and permissions

### Useful Commands

```bash
# Check instance status
aws lightsail get-instance --instance-name shisha-log-dev

# Check if ports are open
aws lightsail get-instance-port-states --instance-name shisha-log-dev

# SSH into instance
ssh ubuntu@$(terraform output -raw static_ip_address)

# Restart application
sudo systemctl restart shisha-log

# Check application status
sudo systemctl status shisha-log
```

## Security Notes

- Never commit `.env` or `.env.prod` files to version control
- Rotate JWT secrets regularly
- Monitor AWS usage and costs
- Keep Docker images updated with security patches
- Use strong passwords for all services

## Cleanup

To destroy infrastructure:

```bash
# Development
make infra-destroy-dev

# Production
make infra-destroy-prod
```

**Warning**: This will permanently delete your infrastructure and data.