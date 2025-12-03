# infrastructure/modules/ai/sns_notifications.tf

# 1. SNS Topic for AI job completions
resource "aws_sns_topic" "ai_job_completion_topic" {
  name = "VOD-${var.environment}-AIJobCompletionTopic"
}

# 2. IAM Role for AI services to publish to the SNS topic
resource "aws_iam_role" "ai_service_sns_role" {
  name = "VOD-${var.environment}-AIServiceSNSRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = [
            "rekognition.amazonaws.com",
            "transcribe.amazonaws.com"
          ]
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# 3. IAM Policy to allow publishing to the SNS topic
resource "aws_iam_policy" "sns_publish_policy" {
  name   = "VOD-${var.environment}-SNSPublishPolicy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.ai_job_completion_topic.arn
      }
    ]
  })
}

# 4. Attach the policy to the role
resource "aws_iam_role_policy_attachment" "sns_publish_attachment" {
  role       = aws_iam_role.ai_service_sns_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}
