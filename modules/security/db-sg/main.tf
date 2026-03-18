# App Common Security Groups
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
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
    protocol    = "1"
    cidr_blocks = [var.vpc_cidr]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

