provider "aws" {
  region = var.region
  alias  = "default-provider"
}

data "archive_file" "greeting" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = var.output_path
}

resource "aws_iam_role" "greeting_role" {
  name               = "greeting_role"
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "greeting_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "greeting_iam_policy" {
  name        = "greeting_iam_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy" {
  role       = aws_iam_role.greeting_role.name
  policy_arn = aws_iam_policy.greeting_iam_policy.arn
}

resource "aws_lambda_function" "greeting" {
  filename      = var.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.greeting_role.arn
  handler       = "lambda.greeting"

  source_code_hash = filebase64sha256(var.output_path)
  runtime          = "python3.8"

  environment {
    variables = {
      greeting = "hello"
    }
  }
}