# Networking Module
module "vpc" {
  source = "../../../modules/vpc"

  vpc                 = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  create_nat          = var.create_nat
  environment         = var.environment
}

# Security Module
module "alb_security_group" {
  source = "../../../modules/security/alb-sg"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
}

module "app_security_group" {
  source = "../../../modules/security/app-sg"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  alb_security_group_id = module.alb_security_group.alb_security_group_id
}

module "db_security_group" {
  source = "../../../modules/security/db-sg"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  app_security_group_id = module.app_security_group.app_security_group_id
}



# Load Balancer Module
module "loadbalancer" {
  source = "../../../modules/loadbalancer"

  alb_security_group_ids = [module.alb_security_group.alb_security_group_id]
  subnet_ids             = module.vpc.public_subnet_ids
  environment            = var.environment
  acm_arn                = var.acm_arn
}
