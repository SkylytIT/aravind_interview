provider "aws" {
  region = "us-east-1"
}

# Raw Images S3 Bucket
resource "aws_s3_bucket" "raw_images" {
  bucket = "raw-images-bucket"
}

# Processed Images S3 Bucket
resource "aws_s3_bucket" "processed_images" {
  bucket = "processed-images-bucket"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-image-processing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda Access to S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "LambdaS3AccessPolicy"
  description = "Policy for Lambda to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.raw_images.arn}/*",
          "${aws_s3_bucket.processed_images.arn}/*"
        ]
      }
    ]
  })
}

# Attach IAM Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Lambda Function for Image Processing
resource "aws_lambda_function" "image_processing" {
  function_name    = "image-processing"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  filename         = "lambda_image_processing.zip"  # Ensure this ZIP contains your Lambda code
  source_code_hash = filebase64sha256("lambda_image_processing.zip")
}

# S3 Event Trigger for Lambda
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = aws_s3_bucket.raw_images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processing.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Lambda Permission for S3 Invocation
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processing.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_images.arn
}
