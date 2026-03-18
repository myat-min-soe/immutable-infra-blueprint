variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "stage" {
  type    = string
  default = "develop"
}

variable "ami_prefix" {
  type    = string
  default = "base"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3a.small"
}

variable "install_nginx" {
  type    = bool
  default = true
}

variable "install_docker" {
  type    = bool
  default = true
}

variable "install_docker_compose" {
  type    = bool
  default = true
}

variable "install_mysql_client" {
  type    = bool
  default = true
}

variable "install_mysql_server" {
  type    = bool
  default = true
}
