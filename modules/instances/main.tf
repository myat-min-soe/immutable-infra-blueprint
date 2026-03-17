data "aws_ami" "Demo_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["Demo-base-image"]
  }

  filter {
    name   = "tag:ManagedBy"
    values = ["Atmos/Packer"]
  }
}

resource "aws_instance" "this" {
  ami                           = var.ami_id != "" ? var.ami_id : data.aws_ami.Demo_ami.id
  instance_type                 = var.instance_type
  subnet_id                     = var.private_subnet_id
  iam_instance_profile          = var.iam_instance_profile
  vpc_security_group_ids        = [var.security_group_id]
  disable_api_termination       = var.disable_api_termination

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  lifecycle {
     create_before_destroy = true
   }
  tags = {
    Name = "Demo-${var.environment}-Instance"
    inplace = "true"
  }
}