variable "environment" {
  description = "APP environment (e.g., dev, staging, prod)"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID of the App"
  type        = string
}

