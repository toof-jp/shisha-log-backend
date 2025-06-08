# GitHub Actions Setup Guide

## AWS Credentials Setup

### 1. Create IAM User via AWS CLI

```bash
# Create user
aws iam create-user --user-name github-actions-shisha-log

# Create access key
aws iam create-access-key --user-name github-actions-shisha-log
```

### 2. Attach Policy

```bash
# Create policy
aws iam create-policy \
  --policy-name GitHubActionsShishaLogPolicy \
  --policy-document file://infra/github-actions-policy.json

# Attach policy
aws iam attach-user-policy \
  --user-name github-actions-shisha-log \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActionsShishaLogPolicy
```

### 3. Get AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

## Required GitHub Secrets

Add these secrets to your repository:

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| AWS_ACCESS_KEY_ID | IAM user access key | From IAM user creation |
| AWS_SECRET_ACCESS_KEY | IAM user secret key | From IAM user creation |
| AWS_ACCOUNT_ID | Your AWS account ID | `aws sts get-caller-identity` |
| SUPABASE_URL | Supabase project URL | Supabase dashboard → Settings → API |
| SUPABASE_ANON_KEY | Supabase anonymous key | Supabase dashboard → Settings → API |
| SUPABASE_SERVICE_ROLE_KEY | Supabase service role key | Supabase dashboard → Settings → API |
| JWT_SECRET | JWT signing secret | Generate a secure random string |
| DATABASE_URL | PostgreSQL connection string | Supabase dashboard → Settings → Database |

## Setting Secrets in GitHub

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with its corresponding value

## Security Best Practices

1. **Rotate credentials regularly** (every 3 months)
2. **Use least privilege principle** for IAM policies
3. **Monitor usage** with AWS CloudTrail
4. **Never commit secrets** to your repository
5. **Use environment-specific secrets** for dev/prod separation