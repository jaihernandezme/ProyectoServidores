# Archivo de variables de Terraform

variable "environment" {
  description = "El entorno de despliegue (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
