# infrastructure/modules/compute/variables.tf

variable "raw_bucket_name" {
  description = "El nombre del bucket S3 para videos crudos."
  type        = string
}

variable "processed_bucket_name" {
  description = "El nombre del bucket S3 para videos procesados."
  type        = string
}

variable "mediaconvert_role_arn" {
  description = "El ARN del rol de IAM para MediaConvert."
  type        = string
}

variable "sns_topic_arn" {
  description = "El ARN del tema de SNS para notificaciones."
  type        = string
}

variable "sns_role_arn" {
  description = "El ARN del rol de IAM para que los servicios de IA publiquen en SNS."
  type        = string
}

variable "dynamodb_table_name" {
  description = "El nombre de la tabla de DynamoDB."
  type        = string
}

variable "opensearch_endpoint" {
  description = "El endpoint del cluster de OpenSearch."
  type        = string
}
