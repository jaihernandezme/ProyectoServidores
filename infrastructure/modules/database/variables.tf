# infrastructure/modules/database/variables.tf

variable "environment" {
  description = "El entorno de despliegue (ej. dev, prod)."
  type        = string
}

variable "search_principal_arn" {
  description = "El ARN del principal de IAM que puede acceder a OpenSearch."
  type        = string
}
