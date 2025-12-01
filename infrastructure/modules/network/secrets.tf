# infrastructure/modules/network/secrets.tf

resource "aws_secretsmanager_secret" "cloudfront_private_key" {
  name = "VOD-${var.environment}-CloudFrontPrivateKey"
}

resource "aws_secretsmanager_secret_version" "cloudfront_private_key_version" {
  secret_id     = aws_secretsmanager_secret.cloudfront_private_key.id
  secret_string = tls_private_key.cloudfront_signer.private_key_pem
}
