resource "aws_s3_bucket" "privileged_actions" {
  bucket = "iam-privileged-actions-${local.account_id}-${var.region}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "privileged_actions" {
  bucket = aws_s3_bucket.privileged_actions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "privileged_actions" {
  bucket = aws_s3_bucket.privileged_actions.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "privileged_actions" {
  bucket = aws_s3_bucket.privileged_actions.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "privileged_actions_file" {
  bucket       = aws_s3_bucket.privileged_actions.id
  key          = "privileged-actions.txt"
  content      = file("${path.module}/files/privileged-actions.txt")
  content_type = "text/plain"
  tags         = local.common_tags
}
