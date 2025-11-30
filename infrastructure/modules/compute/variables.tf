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
