# infrastructure/modules/ai/ai_service_policy.tf

resource "aws_iam_policy" "ai_services_policy" {
  name        = "VOD-${var.environment}-AIServicesPolicy"
  description = "Permisos para AWS Rekognition y Transcribe"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rekognition:StartContentModeration",
          "rekognition:GetContentModeration",
          "rekognition:StartLabelDetection",
          "rekognition:GetLabelDetection",
          "transcribe:StartTranscriptionJob",
          "transcribe:GetTranscriptionJob"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ai_service_policy_attach" {
  role       = aws_iam_role.ai_service_role.name
  policy_arn = aws_iam_policy.ai_services_policy.arn
}
