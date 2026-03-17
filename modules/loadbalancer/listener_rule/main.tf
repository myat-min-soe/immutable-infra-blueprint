# # Listener rule for domain
resource "aws_lb_listener_rule" "this" {
  listener_arn = var.https_listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
} 
