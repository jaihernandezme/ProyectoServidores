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
