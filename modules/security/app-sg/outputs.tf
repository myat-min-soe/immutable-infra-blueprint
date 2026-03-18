output "app_security_group_id" {
  description = "ID of the App security group"
  value       = aws_security_group.app.id
}

