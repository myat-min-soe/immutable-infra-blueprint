output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.instance_profile.name
}

output "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "github_action_user_name" {
  description = "Name of the GitHub Actions IAM user"
  value       = aws_iam_user.cicd_user.name
}

output "github_action_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.cicd_user.arn
} 