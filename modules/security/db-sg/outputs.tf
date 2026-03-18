output "db_security_group_id" {
  description = "ID of the DB security group"
  value       = aws_security_group.db.id
}

