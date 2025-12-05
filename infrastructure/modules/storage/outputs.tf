# infrastructure/modules/storage/outputs.tf

output "raw_bucket_name" {
  description = "El nombre del bucket S3 para videos crudos."
  value       = aws_s3_bucket.raw.bucket
}

output "processed_bucket_name" {
  description = "El nombre del bucket S3 para videos procesados."
  value       = aws_s3_bucket.processed.bucket
}

output "frontend_bucket_website_endpoint" {
  description = "El endpoint del sitio web del bucket S3 del frontend."
  value       = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
}

output "processed_bucket_regional_domain_name" {
  description = "El nombre de dominio regional del bucket S3 de videos procesados."
  value       = aws_s3_bucket.processed.bucket_regional_domain_name
}
