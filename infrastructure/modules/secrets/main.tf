# infrastructure/modules/secrets/main.tf

# 1. Generar una clave privada RSA de 2048 bits para firmar las URLs
resource "tls_private_key" "cloudfront_signer" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 2. Crear una clave pública en AWS a partir de la clave generada
resource "aws_cloudfront_public_key" "main" {
  comment     = "VOD Platform Signing Key"
  encoded_key = tls_private_key.cloudfront_signer.public_key_pem
  name        = "vod-${var.environment}-signing-key"
}

# 3. Almacenar la clave privada en AWS Secrets Manager
resource "aws_secretsmanager_secret" "cloudfront_private_key" {
  name = "VOD-${var.environment}-CloudFrontPrivateKey"
}

resource "aws_secretsmanager_secret_version" "cloudfront_private_key_version" {
  secret_id     = aws_secretsmanager_secret.cloudfront_private_key.id
  secret_string = tls_private_key.cloudfront_signer.private_key_pem
}
