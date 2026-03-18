data "terraform_remote_state" "base" {
  backend = "s3"
  
  config = {
    bucket = "demo-terraform-backend-storage-mms"
    region = var.region
    key    = "base/${var.environment}/terraform.tfstate"
  }
}

# IAM Module
module "iam" {
  source = "../../../modules/iam"

  region                  = var.region
  environment             = var.environment
  storage_s3_bucket_arn   = module.storage.storage_s3_bucket_arn
  deploy_bucket_arn       = module.codedeploy.deploy_bucket_arn
  cicd_user_name          = var.cicd_user_name
}


#Instance Compute Module

module "compute" {
  source = "../../../modules/instances"

  instance_type             = var.instance_type
  security_group_id         = data.terraform_remote_state.base.outputs.app_common_security_group_id
  private_subnet_id         = data.terraform_remote_state.base.outputs.private_subnet_ids[0]
  iam_instance_profile      = module.iam.ec2_instance_profile_name
  environment               = var.environment
}

module "targetgroup" {
  source   = "../../../modules/loadbalancer/target_group"
  tg_name  = "${var.environment}-app-tg"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id
  instance_id = module.compute.instance_id
}

module "listeners" {
  source = "../../../modules/loadbalancer/listener_rule"

  https_listener_arn    = data.terraform_remote_state.base.outputs.https_listener_arn
  target_group_arn      = module.targetgroup.target_group_arn
  domain_name          = var.domain_name
  priority             = 5
}


# Storage Module
module "storage" {
  source                    = "../../../modules/storage"
  storage_bucket_name       = var.storage_bucket_name
  environment               = var.environment
  aws_id                    = var.aws_id
}


# CodeDeploy Module
module "codedeploy" {
  source = "../../../modules/codedeploy"

  service_role_arn          = module.iam.codedeploy_service_role_arn
  codedeploy_app_name       = var.codedeploy_app_name
  deployment_group_name     = var.deployment_group_name
  deploy_bucket_name        = var.deploy_bucket_name
  instance_name             = module.compute.instance_name
  environment               = var.environment
  aws_id                    = var.aws_id
}

# ECR Module
module "ecr" {
  source = "../../../modules/ecr"

  repository_name = var.ecr_repository_name
  environment      = var.environment
}
