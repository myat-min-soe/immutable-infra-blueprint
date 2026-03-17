variable "environment" {
  description = "APP environment (e.g., dev, staging, prod)"
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