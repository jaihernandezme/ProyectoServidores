# infrastructure/modules/database/databases.tf

# 1. Tabla DynamoDB para metadatos de video
resource "aws_dynamodb_table" "video_metadata" {
  name           = "VOD-${var.environment}-VideoMetadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "VideoID"

  attribute {
    name = "VideoID"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

# 2. Colección de Amazon OpenSearch Serverless para búsquedas
resource "aws_opensearch_collection" "search_collection" {
  name = "vod-${var.environment}-search"
  type = "SEARCH"
}

# Política de acceso a datos para OpenSearch.
# Por ahora, permite acceso total a cualquier principal de AWS.
# En una implementación real, esto se restringiría al ARN del rol de Lambda.
resource "aws_opensearch_access_policy" "data_access" {
  name = "vod-${var.environment}-data-access"
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource     = ["index/vod/*"],
          Permission   = ["aoss:*"]
        }
      ],
      Principal = [var.search_principal_arn]
    }
  ])
}
