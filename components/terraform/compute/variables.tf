variable "region" {
  description = "The AWS region in which the resources are deployed"
  type        = string
}

variable "aws_id" {
  description = "AWS Account ID"
  type        = string
}

variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}

variable "stage" {
  description = "The stage in which the resources are deployed"
  type        = string
}





variable "codedeploy_app_name" {
  description = "Deployment app name"
  type        = string
  default     = ""
}

variable "deployment_group_name" {
  description = "Deployment group name"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}


variable "deploy_bucket_name" {
  description = "Name of the deployment S3 bucket"
  type        = string
  default     = ""
}

variable "storage_bucket_name" {
  description = "Name of the storage S3 bucket"
  type        = string
}

variable "cicd_user_name" {
  description = "Name of the CI/CD IAM user"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
  default     = ""
}



variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to the EC2 instance"
  type        = string
  default     = ""
}
variable "disable_api_termination" {
  description = "Flag to disable API termination of the instance"
  type        = bool
  default     = false
}



variable "priority" {
  type        = number
  description = "The priority for the rule"
  default     = 100
}

variable "target_group_arn" {
  type        = string
  description = "The ARN of the target group"
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "The frontend domain name to match"
  default     = ""
}   


variable "instance_id" {
  type        = string
  description = "The ID of the instance to register with the target group"
  default     = ""
}

variable "instance_name" {
  description = "Name of the EC2 instance for CodeDeploy tagging"
  type        = string
  default     = ""
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository to create"
  type        = string
  default     = ""
}