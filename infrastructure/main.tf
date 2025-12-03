# infrastructure/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Módulos de Infraestructura
module "s3_storage" {
  source             = "./modules/storage"
  environment        = var.environment
  cloudfront_oac_arn = module.network.cloudfront_oac_arn
}

module "databases" {
  source              = "./modules/database"
  environment         = var.environment
  search_principal_arn = module.ai_iam.ai_service_role_arn
}

module "compute_services" {
  source                            = "./modules/compute"
  environment                       = var.environment
  raw_bucket_name                   = module.s3_storage.raw_bucket_name
  processed_bucket_name             = module.s3_storage.processed_bucket_name
  mediaconvert_role_arn             = module.iam_roles.mediaconvert_role_arn
  sns_topic_arn                     = module.ai_iam.sns_topic_arn
  sns_role_arn                      = module.ai_iam.sns_role_arn
  dynamodb_table_name               = module.databases.dynamodb_table_name
  opensearch_endpoint               = module.databases.opensearch_endpoint
  cloudfront_domain_name            = module.network.cloudfront_domain_name
  cloudfront_public_key_id          = module.network.cloudfront_public_key_id
  cloudfront_private_key_secret_arn = module.network.cloudfront_private_key_secret_arn
}


module "ai_iam" {
  source      = "./modules/ai"
  environment = var.environment
}

module "network" {
  source                                = "./modules/network"
  environment                           = var.environment
  frontend_bucket_website_endpoint        = module.s3_storage.frontend_bucket_website_endpoint
  processed_bucket_regional_domain_name = module.s3_storage.processed_bucket_regional_domain_name
  signer_service_lambda_arn             = module.compute_services.signer_service_lambda_arn
  upload_service_lambda_arn             = module.compute_services.upload_service_lambda_arn
}

# Disparadores de Eventos
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "VOD-${var.environment}-S3UploadRule"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": { "bucket": { "name": [module.s3_storage.raw_bucket_name] } }
  })
}

resource "aws_cloudwatch_event_target" "video_processing_target" {
  rule = aws_cloudwatch_event_rule.s3_upload_rule.name
  arn  = module.compute_services.video_processing_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge_s3" {
  statement_id  = "AllowExecutionFromEventBridgeS3"
  action        = "lambda:InvokeFunction"
  function_name = module.compute_services.video_processing_lambda_arn
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
  arn       = module.compute_services.ai_service_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge_mediaconvert" {
  statement_id  = "AllowExecutionFromEventBridgeMediaConvert"
  action        = "lambda:InvokeFunction"
  function_name = module.compute_services.ai_service_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_complete_rule.arn
}

# Conectar DynamoDB Streams a la Lambda de búsqueda
resource "aws_lambda_event_source_mapping" "search_service_dynamodb_trigger" {
  event_source_arn  = module.databases.dynamodb_table_stream_arn
  function_name     = module.compute_services.search_service_lambda_arn
  starting_position = "LATEST"
}

# Configuración del Frontend
resource "null_resource" "configure_frontend" {
  triggers = {
    api_endpoint = module.network.api_endpoint
  }

  provisioner "local-exec" {
    command = "sed -e 's|__API_ENDPOINT__|${self.triggers.api_endpoint}|g' ../frontend/src/config.js.template > ../frontend/src/config.js"
  }
}
