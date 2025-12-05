# infrastructure/modules/storage/s3_buckets.tf

# 1. Bucket para videos crudos (uploads)
resource "aws_s3_bucket" "raw" {
  bucket = "vod-${var.environment}-raw"
}

resource "aws_s3_bucket_versioning" "raw_versioning" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "processed_oac_access" {
  bucket = aws_s3_bucket.processed.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.processed.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# 2. Bucket para videos procesados (HLS/DASH)
resource "aws_s3_bucket" "processed" {
  bucket = "vod-${var.environment}-processed"
}

resource "aws_s3_bucket_versioning" "processed_versioning" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Bucket para el frontend estático (React/Next.js)
resource "aws_s3_bucket" "frontend" {
  bucket = "vod-${var.environment}-frontend"
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Política para permitir el acceso público al bucket del frontend
resource "aws_s3_bucket_policy" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}
