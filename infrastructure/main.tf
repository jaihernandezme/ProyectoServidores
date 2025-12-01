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
  environment = var.environment
}

# Módulo de Bases de Datos (DynamoDB y OpenSearch)
module "databases" {
  source = "./modules/database"
  environment = var.environment
  search_principal_arn = module.ai_iam.ai_service_role_arn
}

# Módulo de IAM para Lambdas
module "lambda_iam" {
  source = "./modules/compute"
  environment = var.environment
  raw_bucket_name        = module.s3_storage.raw_bucket_name
  processed_bucket_name  = module.s3_storage.processed_bucket_name
  mediaconvert_role_arn  = module.mediaconvert_iam.mediaconvert_role_arn
  sns_topic_arn          = module.ai_iam.sns_topic_arn
  sns_role_arn           = module.ai_iam.sns_role_arn
  dynamodb_table_name    = module.databases.dynamodb_table_name
  opensearch_endpoint               = module.databases.opensearch_endpoint
  cloudfront_domain_name            = module.network.cloudfront_domain_name
  cloudfront_public_key_id          = module.network.cloudfront_public_key_id
  cloudfront_private_key_secret_arn = module.network.cloudfront_private_key_secret_arn
}

# Módulo de IAM para MediaConvert
module "mediaconvert_iam" {
  source = "./modules/media"
  environment = var.environment
}

# Módulo de IAM para Servicios de IA
module "ai_iam" {
  source = "./modules/ai"
  environment = var.environment
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

# Módulo de Red (CloudFront y API Gateway)
module "network" {
  source = "./modules/network"
  environment = var.environment
  frontend_bucket_website_endpoint        = module.s3_storage.frontend_bucket_website_endpoint
  processed_bucket_regional_domain_name = module.s3_storage.processed_bucket_regional_domain_name
}

# API Gateway para los servicios del backend
resource "aws_apigatewayv2_api" "main" {
  name          = "VOD-${var.environment}-API"
  protocol_type = "HTTP"
}

# Integración para el servicio de firma de URLs
resource "aws_apigatewayv2_integration" "signer" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_iam.signer_service_lambda_arn
}

resource "aws_apigatewayv2_route" "signer" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /videos/{id}/play"
  target    = "integrations/${aws_apigatewayv2_integration.signer.id}"
}

# Integración para el servicio de subida
resource "aws_apigatewayv2_integration" "upload" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_iam.upload_service_lambda_arn
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /get-presigned-url"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

# Recurso para generar el script del frontend con el endpoint de la API
resource "null_resource" "configure_frontend" {
  triggers = {
    api_endpoint = aws_apigatewayv2_api.main.api_endpoint
  }

  provisioner "local-exec" {
    command = <<EOT
      sed -e 's|__API_ENDPOINT__|${self.triggers.api_endpoint}|g' \
          ../frontend/script.js.template > ../frontend/script.js
    EOT
  }

  depends_on = [aws_apigatewayv2_api.main]
}
