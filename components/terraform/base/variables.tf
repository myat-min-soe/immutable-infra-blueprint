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

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "Value of the CIDR block for the VPC"
}
variable "create_nat" {
  description = "Whether to create NAT gateways"
  type        = bool
  default     = true
}

variable "azs" {
  type        = list(string)
  description = "availability zones for subnets"
}

variable "public_subnet_cidr" {
  type        = list(string)
  description = "public subnets for infra"
}

variable "private_subnet_cidr" {
  type        = list(string)
  description = "private subnets for infra"
}


variable "acm_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
}
