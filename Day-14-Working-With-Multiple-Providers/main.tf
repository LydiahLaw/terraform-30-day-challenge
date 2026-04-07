# Primary bucket — eu-central-1 (default provider)
resource "aws_s3_bucket" "primary" {
  bucket = var.primary_bucket_name
}

# Enable versioning on primary bucket (required for replication)
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replica bucket — eu-west-1 (aliased provider)
resource "aws_s3_bucket" "replica" {
  provider = aws.eu_west
  bucket   = var.replica_bucket_name
}

# Enable versioning on replica bucket (required for replication)
resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.eu_west
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replication configuration on the primary bucket
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary]
}
