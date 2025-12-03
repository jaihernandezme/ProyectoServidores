# infrastructure/modules/storage/s3_buckets.tf

# 1. Bucket para videos crudos (uploads)
resource "aws_s3_bucket" "raw" {
  bucket = "vod-${var.environment}-raw"

  # Habilitar versionado para seguridad
  versioning {
    enabled = true
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
            "AWS:SourceArn" = var.cloudfront_oac_arn
          }
        }
      }
    ]
  })
}

# 2. Bucket para videos procesados (HLS/DASH)
resource "aws_s3_bucket" "processed" {
  bucket = "vod-${var.environment}-processed"

  versioning {
    enabled = true
  }
}

# 3. Bucket para el frontend estático (React/Next.js)
resource "aws_s3_bucket" "frontend" {
  bucket = "vod-${var.environment}-frontend"

  website {
    index_document = "index.html"
    error_document = "index.html" # Para SPAs, redirige todo a index.html
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
