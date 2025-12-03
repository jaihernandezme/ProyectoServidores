# infrastructure/modules/storage/variables.tf

variable "cloudfront_oac_arn" {
  description = "El ARN del Control de Acceso de Origen de CloudFront."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "El ARN de la distribución de CloudFront."
  type        = string
}
