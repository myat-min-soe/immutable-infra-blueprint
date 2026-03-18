
variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}

variable "service_role_arn" {
  description = "CodeDeploy service role ARN"
  type        = string
}

variable "codedeploy_app_name" {
  description = "CodeDeploy application name"
  type        = string
}

variable "deployment_group_name" {
  description = "Deployment group name"
  type        = string
}

variable "deploy_bucket_name" {
  description = "Name of the deployment S3 bucket"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance for CodeDeploy tagging"
  type        = string
  default     = ""
}

variable "aws_id" {
  description = "AWS account ID"
  type        = string
}