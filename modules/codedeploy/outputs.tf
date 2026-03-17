output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.this.deployment_group_name
}

output "deploy_bucket_arn" {
  description = "ARN of the deployment S3 bucket"
  value       = aws_s3_bucket.deploy_bucket.arn
}

output "deploy_bucket_name" {
  description = "Name of the deployment S3 bucket"
  value       = aws_s3_bucket.deploy_bucket.bucket
} 
