# infrastructure/modules/network/variables.tf

variable "frontend_bucket_website_endpoint" {
  description = "El endpoint del sitio web del bucket S3 del frontend."
  type        = string
}

variable "processed_bucket_regional_domain_name" {
  description = "El nombre de dominio regional del bucket S3 de videos procesados."
  type        = string
}

variable "environment" {
  description = "El entorno de despliegue."
  type        = string
}
