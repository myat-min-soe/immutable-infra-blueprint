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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
  default     = ""
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
  default     = "orangeplayapps@gmail.com"
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

variable "acm_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
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

variable "private_subnet_id" {
  description = "Subnet ID where the instance will be launched"
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

variable "https_listener_arn" {
  type        = string
  description = "The ARN of the HTTPS listener"
  default     = ""  
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

variable "frontend_domain_name" {
  type        = string
  description = "The frontend domain name to match"
  default     = ""
}   

variable "backend_domain_name" {
  type        = string
  description = "The backend domain name to match"
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

variable "ecr_repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["Demo-cms-frontend", "Demo-cms-backend"]
}