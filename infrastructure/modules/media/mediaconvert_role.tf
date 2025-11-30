# infrastructure/modules/media/mediaconvert_role.tf

# 1. Definición del Role que MediaConvert puede asumir
resource "aws_iam_role" "mediaconvert_service_role" {
  name               = "VOD-${var.environment}-MediaConvertServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "mediaconvert.amazonaws.com"
      }
    }]
  })
}

# 2. Política de Acceso a S3 para MediaConvert
resource "aws_iam_policy" "mediaconvert_s3_policy" {
  name        = "VOD-${var.environment}-MediaConvertS3Access"
  description = "Permite a MediaConvert leer del bucket RAW y escribir en PROCESSED"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        # Usamos * temporalmente. Idealmente se usarían los ARNs de los Buckets.
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mediaconvert_policy_attach" {
  role       = aws_iam_role.mediaconvert_service_role.name
  policy_arn = aws_iam_policy.mediaconvert_s3_policy.arn
}
