output "storage_s3_bucket_name" {
  description = "Name of the S3 storage bucket"
  value       = aws_s3_bucket.storage.bucket
}

output "storage_s3_bucket_arn" {
  description = "ARN of the S3 storage bucket"
  value       = aws_s3_bucket.storage.arn
} 