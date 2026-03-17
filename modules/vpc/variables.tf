variable "vpc" {
  description = "The name of the VPC for the EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones for the subnets"
  type        = list(string)

}

variable "public_subnet_cidr" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)

}

variable "private_subnet_cidr" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "create_nat" {
  description = "Boolean flag to specify if a NAT gateway should be created"
  type        = bool
  default     = true
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}
