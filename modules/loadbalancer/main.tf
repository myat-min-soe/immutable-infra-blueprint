# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

# HTTP Listener - Redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_arn

  # Default action returns 404 for unmatched requests
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = <<-EOF
        <!DOCTYPE html>
        <html>
        <head>
            <title>404 - Not Found</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    text-align: center;
                    padding: 50px;
                    background-color: #f5f5f5;
                }
                h1 { color: #333; }
                p { color: #666; }
            </style>
        </head>
        <body>
            <h1>404 - Not Found</h1>
            <p>The requested resource could not be found on this server.</p>
        </body>
        </html>
      EOF
      status_code  = "404"
    }
  }
}

