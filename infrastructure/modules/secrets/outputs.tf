# infrastructure/modules/secrets/outputs.tf

output "cloudfront_public_key_id" {
  description = "El ID de la clave pública de CloudFront."
  value       = aws_cloudfront_public_key.main.id
}

output "cloudfront_private_key_secret_arn" {
  description = "El ARN del secreto que almacena la clave privada de CloudFront."
  value       = aws_secretsmanager_secret.cloudfront_private_key.arn
}
