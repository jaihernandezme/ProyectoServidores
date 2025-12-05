# infrastructure/modules/compute/lambda_functions.tf

# 1. Empaquetado de la Lambda de Upload Service
data "archive_file" "upload_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/upload-service"
  output_path = "${path.module}/../../../dist/upload-service.zip"
}

# 2. Definición de la Lambda de Upload Service
resource "aws_lambda_function" "upload_service" {
  function_name = "VOD-${var.environment}-UploadService"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.upload_service_zip.output_path
  source_code_hash = data.archive_file.upload_service_zip.output_base64sha256

  environment {
    variables = {
      RAW_BUCKET_NAME = var.raw_bucket_name
    }
  }
}

# 8. Empaquetado y definición de la Lambda de Signer Service
data "archive_file" "signer_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/signer-service"
  output_path = "${path.module}/../../../dist/signer-service.zip"
}

resource "aws_lambda_function" "signer_service" {
  function_name = "VOD-${var.environment}-SignerService"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = data.archive_file.signer_service_zip.output_path
  source_code_hash = data.archive_file.signer_service_zip.output_base64sha256

  environment {
    variables = {
      CLOUDFRONT_PUBLIC_KEY_ID          = var.cloudfront_public_key_id
      CLOUDFRONT_PRIVATE_KEY_SECRET_ARN = var.cloudfront_private_key_secret_arn
    }
  }
}

# 5. Empaquetado y definición de la Lambda de AI Service
data "archive_file" "ai_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/ai-service"
  output_path = "${path.module}/../../../dist/ai-service.zip"
}

resource "aws_lambda_function" "ai_service" {
  function_name = "VOD-${var.environment}-AIService"
  role          = aws_iam_role.ai_service_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  filename         = data.archive_file.ai_service_zip.output_path
  source_code_hash = data.archive_file.ai_service_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN         = var.sns_topic_arn
      SNS_ROLE_ARN          = var.sns_role_arn
      PROCESSED_BUCKET_NAME = var.processed_bucket_name
    }
  }
}

# 6. Empaquetado y definición de la Lambda de Metadata Service
data "archive_file" "metadata_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/metadata-service"
  output_path = "${path.module}/../../../dist/metadata-service.zip"
}

resource "aws_lambda_function" "metadata_service" {
  function_name = "VOD-${var.environment}-MetadataService"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  filename         = data.archive_file.metadata_service_zip.output_path
  source_code_hash = data.archive_file.metadata_service_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }
}

# 7. Empaquetado y definición de la Lambda de Search Service
data "archive_file" "search_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/search-service"
  output_path = "${path.module}/../../../dist/search-service.zip"
}

resource "aws_lambda_function" "search_service" {
  function_name = "VOD-${var.environment}-SearchService"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  filename         = data.archive_file.search_service_zip.output_path
  source_code_hash = data.archive_file.search_service_zip.output_base64sha256

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
    }
  }
}

# 3. Empaquetado de la Lambda de Video Processing Service
data "archive_file" "video_processing_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/video-processing"
  output_path = "${path.module}/../../../dist/video-processing.zip"
}

# 4. Definición de la Lambda de Video Processing Service
resource "aws_lambda_function" "video_processing" {
  function_name = "VOD-${var.environment}-VideoProcessingService"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  filename         = data.archive_file.video_processing_zip.output_path
  source_code_hash = data.archive_file.video_processing_zip.output_base64sha256

  environment {
    variables = {
      RAW_BUCKET_NAME        = var.raw_bucket_name
      PROCESSED_BUCKET_NAME  = var.processed_bucket_name
      MEDIA_CONVERT_ROLE_ARN = var.mediaconvert_role_arn
    }
  }
}
