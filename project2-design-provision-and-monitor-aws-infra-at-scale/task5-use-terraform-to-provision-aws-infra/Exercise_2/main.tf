provider "aws" {
  profile = var.profile
  region  = var.region_lambda
  alias   = "region-lambda"
}

resource "aws_vpc" "vpc_lambda" {
  provider             = aws.region-lambda
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-lambda"
  }
}

data "aws_availability_zones" "azs" {
  provider = aws.region-lambda
  state    = "available"
}

resource "aws_subnet" "lambda_subnet" {
  provider          = aws.region-lambda
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_lambda.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_security_group" "lambda-sg" {
  provider    = aws.region-lambda
  name        = "lambda-sg"
  description = "Allow 443 and traffic to Lambda SG"
  vpc_id      = aws_vpc.vpc_lambda.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_iam_role_policy" "greeting_policy" {
  name   = "greeting_policy"
  role   = aws_iam_role.greeting_role.id
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1607923244463",
      "Action": "logs:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "greeting_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "greeting_logging_policy" {
  name        = "greeting_iam_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy_attachment" "greeting_lambda_logs" {
  role       = aws_iam_role.greeting_role.name
  policy_arn = aws_iam_policy.greeting_iam_policy.arn
}

resource "aws_lambda_function" "greeting" {
  filename      = var.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.greeting_role.arn
  handler       = "lambda.greeting"

  source_code_hash = filebase64sha256(var.output_path)
  runtime          = "python3.7"

  environment {
    variables = {
      greeting = "hello"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.greeting_lambda_logs,
    aws_cloudwatch_log_group.greeting_log_group,
  ]

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_subnet.id]
    security_group_ids = [aws_security_group.lambda-sg.id]
  }
}