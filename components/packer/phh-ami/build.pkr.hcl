packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${var.environment}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  instance_type = var.instance_type
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }

  ssh_username = "ubuntu"

  tags = {
    Name        = "${var.ami_prefix}-image"
    ManagedBy   = "Atmos/Packer"
    BuildTime   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  }
}

build {
  name = "Demo-ami"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    environment_vars = [
      "INSTALL_NGINX=${var.install_nginx}",
      "INSTALL_DOCKER=${var.install_docker}",
      "INSTALL_DOCKER_COMPOSE=${var.install_docker_compose}",
      "INSTALL_MYSQL_CLIENT=${var.install_mysql_client}",
      "INSTALL_MYSQL_SERVER=${var.install_mysql_server}"
    ]
    script = "./install_packages.sh"
  }
}
