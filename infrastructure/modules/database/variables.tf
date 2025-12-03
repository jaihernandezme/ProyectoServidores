# infrastructure/modules/database/variables.tf

variable "search_principal_arn" {
  description = "El ARN del principal que tendrá acceso a OpenSearch."
  type        = string
}

variable "environment" {
  description = "El entorno de despliegue."
  type        = string
}
