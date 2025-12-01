# infrastructure/modules/media/outputs.tf

output "mediaconvert_role_arn" {
  description = "El ARN del rol de IAM para el servicio de MediaConvert."
  value       = aws_iam_role.mediaconvert_service_role.arn
}
