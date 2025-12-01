# infrastructure/modules/ai/ai_service_role.tf

resource "aws_iam_role" "ai_service_role" {
  name               = "VOD-${var.environment}-AIServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
