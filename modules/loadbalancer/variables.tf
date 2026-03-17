
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_security_group_ids" {
  description = "Security group IDs for ALB"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}


variable "acm_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
}