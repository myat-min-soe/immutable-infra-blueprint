variable "environment" {
  description = "APP environment (e.g., dev, staging, prod)"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}

variable "storage_s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "deploy_bucket_arn" {
  description = "ARN of the deployment S3 bucket"
  type        = string
} 

variable "cicd_user_name" {
  description = "Name of the CI/CD IAM user"
  type        = string
}