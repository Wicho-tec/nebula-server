import {
  to = aws_ecr_repository.nebula
  id = "nebula-server"
}

resource "aws_ecr_repository" "nebula" {
  name                 = "nebula-server"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
  lifecycle {
    prevent_destroy = true
    # Preserve the earlier CI/CD lab's repository configuration and tags.
    ignore_changes = all
  }
}
