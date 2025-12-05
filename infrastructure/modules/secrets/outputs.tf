# infrastructure/modules/secrets/outputs.tf

output "cloudfront_public_key_pem" {
  description = "La clave pública de CloudFront en formato PEM."
  value       = tls_private_key.cloudfront_signer.public_key_pem
}

output "cloudfront_public_key_id" {
  description = "El ID de la clave pública de CloudFront."
  value       = aws_cloudfront_public_key.main.id
}

output "cloudfront_private_key_secret_arn" {
  description = "El ARN del secreto en Secrets Manager que contiene la clave privada de CloudFront."
  value       = aws_secretsmanager_secret.cloudfront_private_key.arn
}
