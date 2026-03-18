variable "repository_name" {
  description = "Name of the ECR repository to create"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "Maximum number of images to keep per repository"
  type        = number
  default     = 30
}
