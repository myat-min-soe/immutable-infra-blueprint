output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The name of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public_subnet[*].id
  description = "The names of the public subnets"
}
output "private_subnet_ids" {
  value       = aws_subnet.private_subnet[*].id
  description = "The names of the private subnets"
}