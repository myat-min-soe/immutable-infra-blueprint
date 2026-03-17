#RDS Postgre Database Module
module "database" {
  source                  = "../../../modules/database"
  environment             = var.environment
  vpc_id                  = dvar.vpc_id
  app_security_group_id   = module.security.app_security_group_id
  private_subnet_ids      = var.private_subnet_ids
  parameter_group_name    = var.parameter_group_name
  parameter_group_family  = var.parameter_group_family
  db_username             = var.db_username
  db_name                 = var.db_name
  allocated_storage       = var.allocated_storage
  instance_class          = var.instance_class
  max_allocated_storage   = var.max_allocated_storage
  engine                  = var.engine
  engine_version          = var.engine_version
  db_identifier_name      = var.db_identifier_name
  avail_zone              = var.db_avail_zone
  storage_type            = var.storage_type
  multi_az                = var.multi_az
}

    
