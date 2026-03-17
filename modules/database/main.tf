# App Common Security Groups
resource "aws_security_group" "this" {
  name        = "Demo-${var.environment}-db-sg"
  description = "Security group for DB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Connection from App"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Allow outbound to local VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Demo-${var.environment}-db-sg"
  }
}



resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "private-db-subnet-group"
  subnet_ids = [
    var.private_subnet_ids[0],  # First private subnet
    var.private_subnet_ids[1]   # Second private subnet
  ]

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "pg_parameter_group" {
  name   = var.parameter_group_name
  family = var.parameter_group_family

  parameter {
    name  = "rds.force_ssl"
    value = "0"
    # apply_method = "immediate"
  }

  parameter {
    name  = "password_encryption"
    value = "md5"
    # apply_method = "immediate" 
  }
}

resource "aws_db_instance" "rds" {
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  vpc_security_group_ids      = [aws_security_group.this.id]
  availability_zone           = var.avail_zone
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name        = aws_db_parameter_group.pg_parameter_group.name
  identifier                  = var.db_identifier_name
  multi_az                    = var.multi_az
  skip_final_snapshot         = true
  storage_type                = var.storage_type
  apply_immediately            = true
  storage_encrypted             = true
  backup_retention_period       = 7
  deletion_protection           = true
  performance_insights_enabled  = true
  performance_insights_kms_key_id = aws_kms_key.rds_key.arn
  
  lifecycle {
    prevent_destroy = false
    ignore_changes = [  tags ]
  }
  depends_on = [ aws_db_parameter_group.pg_parameter_group, aws_db_subnet_group.db_subnet_group ]
}

resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption and Performance Insights"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "Demo-${var.environment}-rds-key"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/Demo-${var.environment}-rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

data "aws_vpc" "this" {
  id = var.vpc_id
}
