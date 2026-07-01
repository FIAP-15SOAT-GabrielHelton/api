resource "aws_ecr_repository" "app" {
  name                 = "oficina-mecanica"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "oficina-mecanica-ecr"
  }
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}
