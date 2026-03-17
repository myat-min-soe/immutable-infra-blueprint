# IAM Role and Policy
resource "aws_iam_role" "ec2_role" {
  name = "Demo-${var.environment}-ec2-role"
  assume_role_policy = file("${path.module}/iam-policies/ec2-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "imagebuilder_instance_profile" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "s3_full_access" {
  name        = "Demo-${var.environment}-storage-s3-full-access"
  description = "Full access to storage bucket"

  policy = templatefile("${path.module}/iam-policies/s3-full-access-policy.json", {
    s3_bucket_arn = var.storage_s3_bucket_arn
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_full_access.arn
}

resource "aws_iam_policy" "parameter_store_read" {
  name        = "Demo-${var.environment}-parameter-store-read"
  description = "Read access to /api/* parameters"

  policy = templatefile("${path.module}/iam-policies/parameter-store-read-policy.json", {
    aws_region = var.region
  })
}

resource "aws_iam_role_policy_attachment" "parameter_store_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.parameter_store_read.arn
}

resource "aws_iam_policy" "codedeploy_policy" {
  name        = "Demo-${var.environment}-codeDeploy-policy"
  description = "Policy for EC2 instances to interact with CodeDeploy and related services"

  policy = templatefile("${path.module}/iam-policies/codedeploy-policy.json", {
    deploy_bucket_arn     = var.deploy_bucket_arn
    aws_region        = var.region
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "Demo-${var.environment}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "Demo-${var.environment}-codedeploy-service-role"

  assume_role_policy = file("${path.module}/iam-policies/codedeploy-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# Custom policy for Blue/Green deployments with Auto Scaling
resource "aws_iam_policy" "codedeploy_autoscaling_policy" {
  name        = "Demo-${var.environment}-codedeploy-autoscaling"
  description = "Policy for CodeDeploy to manage Auto Scaling Groups during Blue/Green deployments"

  policy = file("${path.module}/iam-policies/codedeploy-autoscaling-policy.json")
}

resource "aws_iam_role_policy_attachment" "codedeploy_autoscaling_policy_attach" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = aws_iam_policy.codedeploy_autoscaling_policy.arn
}

# IAM Policy for CICD CodeDeploy
resource "aws_iam_policy" "cicd_codedeploy" {
  name        = "Demo-${var.environment}-cicd-codedeploy"
  description = "Policy for CICD to interact with CodeDeploy"
  policy = file("${path.module}/iam-policies/cicd-codedeploy-policy.json")
}

# IAM Policy for CICD S3 Management
resource "aws_iam_policy" "cicd_manage_app_zip" {
  name        = "Demo-${var.environment}-cicd-manage-app-zip"
  description = "Policy for CICD to manage app zip files in S3"
  policy = templatefile("${path.module}/iam-policies/cicd-s3-policy.json", {
    deploy_bucket_arn = var.deploy_bucket_arn
  })
}

# IAM User for CICD
resource "aws_iam_user" "cicd_user" {
  name = var.cicd_user_name

  tags = {
    Name = var.cicd_user_name
  }
}

# IAM Group for CICD
resource "aws_iam_group" "cicd_group" {
  name = "Demo-${var.environment}-cicd-group"
}

# Add CICD User to Group
resource "aws_iam_user_group_membership" "cicd_user_membership" {
  user = aws_iam_user.cicd_user.name
  groups = [
    aws_iam_group.cicd_group.name
  ]
}

# Attach policies to the CICD group
resource "aws_iam_group_policy_attachment" "github_codedeploy_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = aws_iam_policy.cicd_codedeploy.arn
}

resource "aws_iam_group_policy_attachment" "github_s3_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = aws_iam_policy.cicd_manage_app_zip.arn
}

# Enforce MFA for the CICD Group
data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid       = "DenyAllExceptListedIfNoMFA"
    effect    = "Deny"
    not_actions = ["iam:*"]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "Demo-${var.environment}-enforce-mfa"
  description = "Enforce MFA for all actions except IAM"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

resource "aws_iam_group_policy_attachment" "enforce_mfa_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# ECR PowerUser Policy for EC2 Role (Docker pull)
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ECR PowerUser Policy for CI/CD Group (Docker build & push)
resource "aws_iam_group_policy_attachment" "cicd_ecr_power_user" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
