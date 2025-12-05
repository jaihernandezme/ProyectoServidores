# infrastructure/modules/iam_roles/variables.tf

variable "environment" {
  description = "El entorno de despliegue (ej. dev, prod)."
  type        = string
}
