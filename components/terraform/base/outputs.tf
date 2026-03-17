output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The name of the VPC from the module"
}


output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.loadbalancer.alb_zone_id
}

output "app_common_security_group_id" {
  description = "ID of the App common security group"
  value       = module.security.app_security_group_id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = module.loadbalancer.https_listener_arn
}