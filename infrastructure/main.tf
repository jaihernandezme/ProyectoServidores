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

  raw_bucket_name        = module.s3_storage.raw_bucket_name
  processed_bucket_name  = module.s3_storage.processed_bucket_name
  mediaconvert_role_arn = module.mediaconvert_iam.mediaconvert_role_arn
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

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  arn       = module.lambda_iam.video_processing_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_iam.video_processing_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_upload_rule.arn
}
