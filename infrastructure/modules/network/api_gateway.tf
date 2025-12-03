# infrastructure/modules/network/api_gateway.tf

# API Gateway para los servicios del backend
resource "aws_apigatewayv2_api" "main" {
  name          = "VOD-${var.environment}-API"
  protocol_type = "HTTP"
}

# Integración para el servicio de firma de URLs
resource "aws_apigatewayv2_integration" "signer" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.signer_service_lambda_arn
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
  integration_uri  = var.upload_service_lambda_arn
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /get-presigned-url"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}
