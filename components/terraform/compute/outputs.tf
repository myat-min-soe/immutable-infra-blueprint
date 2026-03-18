output "storage_bucket_name" {
  description = "Name of the S3 storage bucket"
  value       = module.storage.storage_s3_bucket_name
} 

output "deploy_bucket_name" {
  description = "Name of the deployment S3 bucket"
  value       = module.codedeploy.deploy_bucket_name
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.compute.instance_public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.compute.instance_private_ip
}

output "instance_name" {
  description = "Name of the EC2 instance"
  value       = module.compute.instance_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.targetgroup.target_group_arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = module.targetgroup.target_group_name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}