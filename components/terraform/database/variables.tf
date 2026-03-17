variable "environment" {
  description = "Environment for the database"
  type        = string
}
variable "db_username" {
  description = "database username"
  type        = string
}
variable "db_name" {
  description = "database name"
  type        = string
}
variable "allocated_storage" {
  description = "database allocated_storage"
  type        = string
}
variable "instance_class" {
  description = "database instance class"
  type        = string
}
variable "max_allocated_storage" {
  description = "database max_allocated_storage"
  type        = string
}
variable "engine" {
  description = "database engine"
  type        = string
}
variable "engine_version" {
  description = "database engine_version"
  type        = string
}
variable "db_identifier_name" {
  description = "database instance_name"
  type        = string
}
variable "db_avail_zone" {
#   description = "database avail_zones"
  type        = string
}

variable "storage_type" {
  description = "database storage type"
  type        = string
}
#ingress
variable "postgre_sg_ingress_rules" {
  description = "Ingress Rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
    description = string
  }))
  default = []
}
#egress
variable "postgre_sg_egress_rules" {
  description = "Egress Rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
    description = string
  }))
  default = []
}
variable "region" {
  description = "aws region"
  type = string
}
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  
}

variable "parameter_group_name" {
  description = "database parameter group name"
  type        = string
}
variable "parameter_group_family" {
  description = "database parameter group family"
  type        = string
}
