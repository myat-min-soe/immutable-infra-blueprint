# S3 Bucket for deployments
# tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "deploy_bucket" {
  bucket = var.deploy_bucket_name

  tags = {
    Name = var.deploy_bucket_name
  }
}

# Enable encryption for deployment bucket using KMS
resource "aws_kms_key" "deploy_bucket_key" {
  description             = "KMS key for Deploy S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "Demo-${var.environment}-deploy-bucket-key"
  }
}

resource "aws_kms_alias" "deploy_bucket_key_alias" {
  name          = "alias/Demo-${var.environment}-deploy-bucket-key"
  target_key_id = aws_kms_key.deploy_bucket_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_bucket" {
  bucket = aws_s3_bucket.deploy_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.deploy_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Access logging for deployment bucket
# tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "deploy_log_bucket" {
  bucket = "${var.deploy_bucket_name}-logs"
}



resource "aws_s3_bucket_public_access_block" "deploy_log_bucket" {
  bucket = aws_s3_bucket.deploy_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_log_bucket" {
  bucket = aws_s3_bucket.deploy_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.deploy_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "deploy_log_bucket" {
  bucket        = aws_s3_bucket.deploy_log_bucket.id
  target_bucket = aws_s3_bucket.deploy_log_bucket.id
  target_prefix = "self-logs/"
}

resource "aws_s3_bucket_logging" "deploy_bucket" {
  bucket        = aws_s3_bucket.deploy_bucket.id
  target_bucket = aws_s3_bucket.deploy_log_bucket.id
  target_prefix = "log/"
}

# Block public access for deployment bucket
resource "aws_s3_bucket_public_access_block" "deploy_bucket" {
  bucket = aws_s3_bucket.deploy_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# Lifecycle policy for deployment bucket - packages directory retention
resource "aws_s3_bucket_lifecycle_configuration" "deploy_bucket" {
  bucket = aws_s3_bucket.deploy_bucket.id

  rule {
    id     = "packages_retention_policy"
    status = "Enabled"

    filter {
      prefix = "packages/"
    }


    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}