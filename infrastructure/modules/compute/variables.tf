# infrastructure/modules/compute/variables.tf

variable "environment" {
  description = "El entorno de despliegue (ej. dev, prod)."
  type        = string
}

variable "raw_bucket_name" {
  description = "Nombre del bucket S3 para videos crudos."
  type        = string
}

variable "processed_bucket_name" {
  description = "Nombre del bucket S3 para videos procesados."
  type        = string
}

variable "mediaconvert_role_arn" {
  description = "ARN del rol de IAM para MediaConvert."
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del tópico SNS para notificaciones de IA."
  type        = string
}

variable "sns_role_arn" {
  description = "ARN del rol de IAM para que los servicios de IA publiquen en SNS."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para metadatos."
  type        = string
}

variable "opensearch_endpoint" {
  description = "Endpoint del clúster de OpenSearch."
  type        = string
}

variable "cloudfront_public_key_id" {
  description = "ID de la clave pública de CloudFront para firmar URLs."
  type        = string
}

variable "cloudfront_private_key_secret_arn" {
  description = "ARN del secreto en Secrets Manager con la clave privada de CloudFront."
  type        = string
}

variable "lambda_exec_role_arn" {
  description = "ARN del rol de ejecución de Lambda."
  type        = string
}

variable "ai_service_role_arn" {
  description = "ARN del rol del servicio de IA."
  type        = string
}
