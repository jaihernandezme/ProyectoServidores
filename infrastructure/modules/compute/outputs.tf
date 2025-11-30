# infrastructure/modules/compute/outputs.tf

output "lambda_exec_role_arn" {
  description = "El ARN del rol de IAM para la ejecución general de Lambdas."
  value       = aws_iam_role.lambda_exec_role.arn
}

output "video_processing_lambda_arn" {
  description = "El ARN de la función Lambda de procesamiento de video."
  value       = aws_lambda_function.video_processing.arn
}
