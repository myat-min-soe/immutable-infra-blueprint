resource "aws_kms_key" "ecr_key" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "ecr_key_alias" {
  name          = "alias/-${var.environment}-ecr-key"
  target_key_id = aws_kms_key.ecr_key.key_id
}
