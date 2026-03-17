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
module "security" {
  source = "../../../modules/security"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
}



# Load Balancer Module
module "loadbalancer" {
  source = "../../../modules/loadbalancer"

  alb_security_group_ids = [module.security.alb_security_group_id]
  subnet_ids             = module.vpc.public_subnet_ids
  environment            = var.environment
  acm_arn                = var.acm_arn
}
