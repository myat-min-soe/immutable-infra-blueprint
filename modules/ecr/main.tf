# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_key.arn
  }

  tags = {
    Name        = each.value
    Environment = var.environment
  }
}

# Lifecycle Policy - keep only recent images
resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each   = aws_ecr_repository.repositories
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
