output "instance_name" {
  description = "Name of the Lightsail instance"
  value       = module.lightsail.instance_name
}

output "static_ip_address" {
  description = "Static IP address for DNS configuration"
  value       = module.lightsail.static_ip_address
}

output "instance_id" {
  description = "ID of the Lightsail instance"
  value       = module.lightsail.instance_id
}

output "dns_instructions" {
  description = "Instructions for DNS configuration"
  value = <<-EOT
    Please configure your domain DNS settings:
    
    A Record: ${var.domain_name} -> ${module.lightsail.static_ip_address}
    
    SSL certificate will be automatically obtained after DNS propagation (usually 5-30 minutes).
    Check status: ssh ubuntu@${module.lightsail.static_ip_address} 'sudo journalctl -u setup-ssl.service'
    
    To manually trigger SSL setup:
    ssh ubuntu@${module.lightsail.static_ip_address} 'sudo /opt/shisha-log/setup-ssl.sh'
  EOT
}