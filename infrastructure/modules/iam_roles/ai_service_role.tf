# infrastructure/modules/iam_roles/ai_service_role.tf

resource "aws_iam_role" "ai_service_role" {
  name = "VOD-${var.environment}-AIServiceRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ai_service_s3_access" {
  role       = aws_iam_role.ai_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ai_service_transcribe_access" {
  role       = aws_iam_role.ai_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess"
}

resource "aws_iam_role_policy_attachment" "ai_service_rekognition_access" {
  role       = aws_iam_role.ai_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRekognitionFullAccess"
}
