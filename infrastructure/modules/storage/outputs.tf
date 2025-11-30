# infrastructure/modules/storage/outputs.tf

output "raw_bucket_name" {
  description = "El nombre del bucket S3 para videos crudos."
  value       = aws_s3_bucket.raw.bucket
}
