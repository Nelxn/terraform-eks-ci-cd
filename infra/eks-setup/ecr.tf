resource "aws_ecr_repository" "myapp" {
  name                 = "myapp-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


