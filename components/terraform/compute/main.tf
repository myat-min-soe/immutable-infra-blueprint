# IAM Module
module "iam" {
  source = "../../../modules/iam"

  region                  = var.region
  environment             = var.environment
  storage_s3_bucket_arn   = module.storage.storage_s3_bucket_arn
  deploy_bucket_arn       = module.codedeploy.deploy_bucket_arn
  cicd_user_name          = var.cicd_user_name
}

# Security Module
module "security" {
  source = "../../../modules/security"

  environment     = var.environment
  vpc_id          = var.vpc_id
  alb_security_group_id = var.alb_security_group_id
}


#Instance Compute Module

module "compute" {
  source = "../../../modules/instances"

  instance_type             = var.instance_type
  security_group_id         = module.security.app_security_group_id
  private_subnet_id         = var.private_subnet_id
  iam_instance_profile      = module.iam.ec2_instance_profile_name
  environment               = var.environment
}

module "targetgroup" {
  source   = "../../../modules/loadbalancer/target_group"
  tg_name  = "Demo-${var.environment}-app-tg"
  vpc_id   = var.vpc_id
  instance_id = module.compute.instance_id
}

module "frontend_listeners" {
  source = "../../../modules/loadbalancer/listener_rule"

  https_listener_arn    = var.https_listener_arn
  target_group_arn      = module.targetgroup.target_group_arn
  domain_name          = var.frontend_domain_name
  priority             = 5
}

module "backend_listeners" {
  source = "../../../modules/loadbalancer/listener_rule"

  https_listener_arn     = var.https_listener_arn
  target_group_arn      = module.targetgroup.target_group_arn
  domain_name          = var.backend_domain_name
  priority             = 6
} 

# Storage Module
module "storage" {
  source                    = "../../../modules/storage"
  storage_bucket_name       = var.storage_bucket_name
  environment               = var.environment
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
}

# ECR Module
module "ecr" {
  source = "../../../modules/ecr"

  repository_names = var.ecr_repository_names
  environment      = var.environment
}
