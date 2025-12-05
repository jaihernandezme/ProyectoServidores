# infrastructure/modules/network/variables.tf

variable "environment" {
  description = "El entorno de despliegue (ej. dev, prod)."
  type        = string
}

variable "frontend_bucket_website_endpoint" {
  description = "El endpoint del sitio web del bucket S3 del frontend."
  type        = string
}

variable "processed_bucket_regional_domain_name" {
  description = "El nombre de dominio regional del bucket S3 de videos procesados."
  type        = string
}

variable "signer_service_lambda_arn" {
  description = "El ARN de la función Lambda del servicio de firma."
  type        = string
}

variable "upload_service_lambda_arn" {
  description = "El ARN de la función Lambda del servicio de subida."
  type        = string
}

variable "cloudfront_public_key_pem" {
  description = "La clave pública de CloudFront en formato PEM."
  type        = string
}

variable "cloudfront_public_key_id" {
  description = "El ID de la clave pública de CloudFront."
  type        = string
}
