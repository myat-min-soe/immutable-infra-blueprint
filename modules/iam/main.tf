# ============================================================
# EC2 Instance Role
# ============================================================

resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-ec2-role"
  assume_role_policy = file("${path.module}/iam-policies/ec2-assume-role-policy.json")
}

# AWS Managed — SSM Session Manager (zero SSH)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# AWS Managed — EC2 Image Builder
resource "aws_iam_role_policy_attachment" "imagebuilder_instance_profile" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

# AWS Managed — CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# AWS Managed — CodeDeploy Agent on EC2
resource "aws_iam_role_policy_attachment" "codedeploy_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# AWS Managed — ECR pull (docker pull from ECR)
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Custom — S3 storage bucket access
resource "aws_iam_policy" "s3_full_access" {
  name        = "${var.environment}-storage-s3-full-access"
  description = "Full access to storage bucket"

  policy = templatefile("${path.module}/iam-policies/s3-full-access-policy.json", {
    s3_bucket_arn = var.storage_s3_bucket_arn
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_full_access.arn
}

# Custom — SSM Parameter Store read (/api/*)
resource "aws_iam_policy" "parameter_store_read" {
  name        = "${var.environment}-parameter-store-read"
  description = "Read access to /api/* parameters"

  policy = templatefile("${path.module}/iam-policies/parameter-store-read-policy.json", {
    aws_region = var.region
  })
}

resource "aws_iam_role_policy_attachment" "parameter_store_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.parameter_store_read.arn
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.environment}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ============================================================
# CodeDeploy Service Role
# ============================================================

resource "aws_iam_role" "codedeploy_service_role" {
  name               = "${var.environment}-codedeploy-service-role"
  assume_role_policy = file("${path.module}/iam-policies/codedeploy-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ============================================================
# CI/CD IAM User + Group
# ============================================================

resource "aws_iam_user" "cicd_user" {
  name = var.cicd_user_name

  tags = {
    Name = var.cicd_user_name
  }
}

resource "aws_iam_group" "cicd_group" {
  name = "${var.environment}-cicd-group"
}

resource "aws_iam_user_group_membership" "cicd_user_membership" {
  user = aws_iam_user.cicd_user.name
  groups = [
    aws_iam_group.cicd_group.name
  ]
}

# ============================================================
# CI/CD Group Policy Attachments
# ============================================================

# AWS Managed — CodeDeploy full access for CI/CD pipeline
# FIXED: directly attach managed policy ARN instead of wrapping
# in aws_iam_policy (which only accepts JSON documents, not ARNs)
resource "aws_iam_group_policy_attachment" "github_codedeploy_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

# AWS Managed — ECR push/pull (docker build & push from CI/CD)
resource "aws_iam_group_policy_attachment" "cicd_ecr_power_user" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Custom — S3 deploy bucket (upload app zip for CodeDeploy)
resource "aws_iam_policy" "cicd_manage_app_zip" {
  name        = "${var.environment}-cicd-manage-app-zip"
  description = "Policy for CICD to manage app zip files in S3"

  policy = templatefile("${path.module}/iam-policies/cicd-s3-policy.json", {
    deploy_bucket_arn = var.deploy_bucket_arn
  })
}

resource "aws_iam_group_policy_attachment" "github_s3_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = aws_iam_policy.cicd_manage_app_zip.arn
}

# ============================================================
# MFA Enforcement for CI/CD Group
# ============================================================

data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"

    not_actions = ["iam:*"]
    resources   = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "${var.environment}-enforce-mfa"
  description = "Enforce MFA for all actions except IAM"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

resource "aws_iam_group_policy_attachment" "enforce_mfa_attach" {
  group      = aws_iam_group.cicd_group.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}
