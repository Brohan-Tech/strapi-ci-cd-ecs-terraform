resource "aws_s3_bucket" "terraform_state" {
  bucket = "rohana-terraform-state"

  # Keep versioning disabled to stay within Free Tier
  force_destroy = true

  tags = {
    Name        = "rohana-terraform-state"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "rohana-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"  # Free tier eligible
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "rohana-terraform-locks"
    Environment = "dev"
  }
}

