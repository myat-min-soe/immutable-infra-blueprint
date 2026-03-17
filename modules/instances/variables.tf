
variable "environment" {
  description = "Environment for the database"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (leave empty to use dynamic Packer AMI)"
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
