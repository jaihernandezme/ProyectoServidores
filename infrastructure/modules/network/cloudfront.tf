# infrastructure/modules/network/cloudfront.tf

# 1. Crear una clave pública en CloudFront a partir de la clave PEM
resource "aws_cloudfront_public_key" "main" {
  comment     = "VOD Platform Public Key"
  name        = "vod-${var.environment}-public-key"
  encoded_key = var.cloudfront_public_key_pem
}

# 2. Crear un grupo de claves que contenga la clave pública
resource "aws_cloudfront_key_group" "main" {
  comment = "VOD Platform Key Group"
  items   = [aws_cloudfront_public_key.main.id]
  name    = "vod-${var.environment}-key-group"
}

# 3. Crear un Control de Acceso de Origen (OAC) para el bucket de videos
resource "aws_cloudfront_origin_access_control" "processed_oac" {
  name                              = "VOD-${var.environment}-OAC-Processed"
  description                       = "OAC for the processed videos bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. Definir la distribución de CloudFront
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "VOD Platform CDN"
  default_root_object = "index.html"

  # Origen 1: Bucket del Frontend (público)
  origin {
    domain_name = var.frontend_bucket_website_endpoint
    origin_id   = "S3-Frontend"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  # Origen 2: Bucket de Videos Procesados (privado con OAC)
  origin {
    domain_name = var.processed_bucket_regional_domain_name
    origin_id   = "S3-Processed-Videos"
    origin_access_control_id = aws_cloudfront_origin_access_control.processed_oac.id
  }

  # Comportamiento de caché por defecto (para el frontend)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Comportamiento de caché para los videos (requiere URLs firmadas)
  ordered_cache_behavior {
    path_pattern     = "/videos/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Processed-Videos"

    trusted_key_groups = [aws_cloudfront_key_group.main.id]

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Configuración general de la distribución
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
