variable "tg_name" {
  type        = string
  default     = ""
  description = "Target Group"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "instance_id" {
  type        = string
  description = "The ID of the instance to register with the target group"
  default     = ""
}
