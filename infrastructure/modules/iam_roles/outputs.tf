# infrastructure/modules/iam_roles/outputs.tf

output "lambda_exec_role_arn" {
  description = "El ARN del rol de ejecución de Lambda."
  value       = aws_iam_role.lambda_exec_role.arn
}

output "mediaconvert_role_arn" {
  description = "El ARN del rol de MediaConvert."
  value       = aws_iam_role.mediaconvert_role.arn
}

output "ai_service_role_arn" {
  description = "El ARN del rol del servicio de IA."
  value       = aws_iam_role.ai_service_role.arn
}
