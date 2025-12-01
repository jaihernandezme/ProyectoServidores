# infrastructure/modules/ai/outputs.tf

output "ai_service_role_arn" {
  description = "El ARN del rol de IAM para el servicio de IA."
  value       = aws_iam_role.ai_service_role.arn
}

output "sns_topic_arn" {
  description = "El ARN del tema de SNS para notificaciones."
  value       = aws_sns_topic.ai_job_completion_topic.arn
}

output "sns_role_arn" {
  description = "El ARN del rol de IAM para que los servicios de IA publiquen en SNS."
  value       = aws_iam_role.ai_service_sns_role.arn
}
