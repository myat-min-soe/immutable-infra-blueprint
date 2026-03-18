resource "aws_codedeploy_app" "this" {
  name             = var.codedeploy_app_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = var.deployment_group_name
  service_role_arn      = var.service_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.instance_name
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
  }

}
