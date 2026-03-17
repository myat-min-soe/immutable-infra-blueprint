variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
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
