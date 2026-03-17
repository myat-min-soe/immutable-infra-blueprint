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

variable "domain_name" {
  type        = string
  description = "The domain name to match"
  default     = ""
}   
