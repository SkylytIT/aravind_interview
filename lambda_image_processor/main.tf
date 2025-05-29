provider "aws" {
  region = "us-east-1"  # change if needed
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-deployment-bucket-12345"  # must be globally unique
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda_image_processor/lambda.zip"
  source = "lambda_image_processor/lambda.zip"  # local path to the ZIP file
  etag   = filemd5("lambda_image_processor/lambda.zip")
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "image_processor" {
  function_name = "ImageProcessorFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_zip.key

  memory_size = 256
  timeout     = 30
}
