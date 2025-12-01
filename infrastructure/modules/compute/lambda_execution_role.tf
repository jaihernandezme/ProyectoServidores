# infrastructure/modules/compute/lambda_execution_role.tf

# 1. Definición del Role que Lambda puede asumir
resource "aws_iam_role" "lambda_exec_role" {
  name               = "VOD-${var.environment}-LambdaExecRole"
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

# 2. Política de Logging (Necesaria para cualquier Lambda)
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Política de Permisos Específicos (Acceso a DynamoDB y S3 - solo lectura/escritura)
resource "aws_iam_policy" "lambda_permissions_policy" {
  name        = "VOD-${var.environment}-LambdaAccessPolicy"
  description = "Permisos generales para DB y S3 (Catálogo y Logs)"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Resource = "*" # En la Fase 2, restringiremos a la ARN específica de DynamoDB
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "*" # En la Fase 2, restringiremos a los ARNs de S3
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_permissions_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions_policy.arn
}

# 4. Política para permitir a la Lambda interactuar con MediaConvert
resource "aws_iam_policy" "lambda_mediaconvert_policy" {
  name        = "VOD-${var.environment}-LambdaMediaConvertPolicy"
  description = "Permite a la Lambda crear y gestionar trabajos de MediaConvert y pasar roles."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "mediaconvert:CreateJob",
          "mediaconvert:DescribeEndpoints"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = "*" # En producción, restringir al ARN del rol de MediaConvert
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_mediaconvert_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_mediaconvert_policy.arn
}

# 5. Política para permitir a la Lambda leer el secreto de la clave privada de CloudFront
resource "aws_iam_policy" "lambda_secretsmanager_policy" {
  name        = "VOD-${var.environment}-LambdaSecretsManagerPolicy"
  description = "Permite a la Lambda leer el secreto de la clave privada de CloudFront."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = var.cloudfront_private_key_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_policy.arn
}
