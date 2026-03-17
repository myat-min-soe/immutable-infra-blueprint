provider "aws" {
  default_tags {
    tags = local.metadata
  }
  region = var.region
}







