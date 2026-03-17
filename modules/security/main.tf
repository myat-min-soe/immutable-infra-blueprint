

# App Common Security Groups
resource "aws_security_group" "app" {
  name        = "Demo-${var.environment}-app-common-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # tfsec:ignore:aws-vpc-no-public-egress-sgr
  egress {
    description = "Allow outbound HTTP for package updates and AWS services"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-vpc-no-public-egress-sgr
  egress {
    description = "Allow outbound HTTPS for AWS services (SSM, ECR, etc.)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "Demo-${var.environment}-app-common-sg"
  }
}

data "aws_vpc" "this" {
  id = var.vpc_id
}
