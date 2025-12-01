# Archivo de variables de Terraform

variable "environment" {
  description = "El entorno de despliegue (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "La región de AWS para el despliegue."
  type        = string
  default     = "us-east-1"
}
