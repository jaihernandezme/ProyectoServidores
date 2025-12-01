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
  mediaconvert_role_arn  = module.mediaconvert_iam.mediaconvert_role_arn
  sns_topic_arn          = module.ai_iam.sns_topic_arn
  sns_role_arn           = module.ai_iam.sns_role_arn
  dynamodb_table_name    = module.databases.dynamodb_table_name
  opensearch_endpoint    = module.databases.opensearch_endpoint
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

# Regla de EventBridge para detectar la finalización de trabajos de MediaConvert
resource "aws_cloudwatch_event_rule" "mediaconvert_complete_rule" {
  name        = "VOD-${var.environment}-MediaConvertCompleteRule"
  description = "Dispara un evento cuando un trabajo de MediaConvert se completa."

  event_pattern = jsonencode({
    "source": ["aws.mediaconvert"],
    "detail-type": ["MediaConvert Job State Change"],
    "detail": {
      "status": ["COMPLETE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ai_service_target" {
  rule      = aws_cloudwatch_event_rule.mediaconvert_complete_rule.name
  arn       = module.lambda_iam.ai_service_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge_mediaconvert" {
  statement_id  = "AllowExecutionFromEventBridgeMediaConvert"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_iam.ai_service_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_complete_rule.arn
}

# Conectar el tema de SNS a la Lambda de metadatos
resource "aws_sns_topic_subscription" "metadata_service_subscription" {
  topic_arn = module.ai_iam.sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.lambda_iam.metadata_service_lambda_arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_iam.metadata_service_lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = module.ai_iam.sns_topic_arn
}

# Conectar DynamoDB Streams a la Lambda de búsqueda
resource "aws_lambda_event_source_mapping" "search_service_dynamodb_trigger" {
  event_source_arn  = module.databases.dynamodb_table_stream_arn
  function_name     = module.lambda_iam.search_service_lambda_arn
  starting_position = "LATEST"
}
