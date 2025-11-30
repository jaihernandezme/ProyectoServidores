# infrastructure/modules/ai/outputs.tf

output "ai_service_role_arn" {
  description = "El ARN del rol de IAM para el servicio de IA."
  value       = aws_iam_role.ai_service_role.arn
}
