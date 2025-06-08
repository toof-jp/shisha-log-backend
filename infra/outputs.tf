output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_ids[0]
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "ssl_certificate_validation_records" {
  description = "DNS validation records for SSL certificate"
  value = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}