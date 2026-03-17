# tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "storage" {
  bucket = var.storage_bucket_name

  tags = {
    Name = var.storage_bucket_name
  }
}



# Enable encryption using KMS
resource "aws_kms_key" "storage_bucket_key" {
  description             = "KMS key for Storage S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "Demo-${var.environment}-storage-bucket-key"
  }
}

resource "aws_kms_alias" "storage_bucket_key_alias" {
  name          = "alias/Demo-${var.environment}-storage-bucket-key"
  target_key_id = aws_kms_key.storage_bucket_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.storage_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Access logging for storage bucket
# tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "storage_log_bucket" {
  bucket = "${var.storage_bucket_name}-logs"
}



resource "aws_s3_bucket_public_access_block" "storage_log_bucket" {
  bucket = aws_s3_bucket.storage_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage_log_bucket" {
  bucket = aws_s3_bucket.storage_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.storage_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "storage_log_bucket" {
  bucket        = aws_s3_bucket.storage_log_bucket.id
  target_bucket = aws_s3_bucket.storage_log_bucket.id
  target_prefix = "self-logs/"
}

resource "aws_s3_bucket_logging" "storage" {
  bucket        = aws_s3_bucket.storage.id
  target_bucket = aws_s3_bucket.storage_log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
} 