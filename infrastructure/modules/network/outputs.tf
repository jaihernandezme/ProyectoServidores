# infrastructure/modules/network/outputs.tf

output "cloudfront_oac_arn" {
  description = "El ARN del Control de Acceso de Origen de CloudFront."
  value       = aws_cloudfront_origin_access_control.processed_oac.arn
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución de CloudFront."
  value       = aws_cloudfront_distribution.main.arn
}

output "api_endpoint" {
  description = "El endpoint de la API Gateway."
  value       = aws_apigatewayv2_api.main.api_endpoint
}
