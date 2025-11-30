# infrastructure/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# Módulo de Almacenamiento (S3 Buckets)
module "s3_storage" {
  source = "./modules/storage"
}

# Módulo de Bases de Datos (DynamoDB y OpenSearch)
module "databases" {
  source = "./modules/database"

  search_principal_arn = module.ai_iam.ai_service_role_arn
}

# Módulo de IAM para Lambdas
module "lambda_iam" {
  source = "./modules/compute"
}

# Módulo de IAM para MediaConvert
module "mediaconvert_iam" {
  source = "./modules/media"
}

# Módulo de IAM para Servicios de IA
module "ai_iam" {
  source = "./modules/ai"
}

# Configuración de EventBridge para detectar uploads a S3
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "VOD-${var.environment}-S3UploadRule"
  description = "Dispara un evento cuando un video se sube al bucket raw."

  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [module.s3_storage.raw_bucket_name]
      }
    }
  })
}

# NOTA: En este punto, no tenemos una Lambda a la que apuntar.
# El siguiente recurso es un marcador de posición que se completará
# cuando la Lambda de procesamiento de video esté definida.

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
#   arn       = "<ARN_DE_LA_LAMBDA_DE_PROCESAMIENTO>"
#   input_transformer {
#     input_paths = {
#       "s3_bucket" = "$.detail.bucket.name",
#       "s3_key"    = "$.detail.object.key"
#     }
#     input_template = "\"{\\\"bucket\\\":<s3_bucket>,\\\"key\\\":<s3_key>}\""
#   }
# }
