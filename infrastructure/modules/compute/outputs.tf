# infrastructure/modules/compute/outputs.tf

output "lambda_exec_role_arn" {
  description = "El ARN del rol de IAM para la ejecución general de Lambdas."
  value       = aws_iam_role.lambda_exec_role.arn
}

output "video_processing_lambda_arn" {
  description = "El ARN de la función Lambda de procesamiento de video."
  value       = aws_lambda_function.video_processing.arn
}

output "ai_service_lambda_arn" {
  description = "El ARN de la función Lambda de servicios de IA."
  value       = aws_lambda_function.ai_service.arn
}

output "metadata_service_lambda_arn" {
  description = "El ARN de la función Lambda de consolidación de metadatos."
  value       = aws_lambda_function.metadata_service.arn
}

output "search_service_lambda_arn" {
  description = "El ARN de la función Lambda de indexación en OpenSearch."
  value       = aws_lambda_function.search_service.arn
}
