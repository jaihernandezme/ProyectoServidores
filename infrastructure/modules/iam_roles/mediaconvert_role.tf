# infrastructure/modules/iam_roles/mediaconvert_role.tf

resource "aws_iam_role" "mediaconvert_role" {
  name = "VOD-${var.environment}-MediaConvertRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "mediaconvert.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mediaconvert_s3_access" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "mediaconvert_api_gateway_access" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}
