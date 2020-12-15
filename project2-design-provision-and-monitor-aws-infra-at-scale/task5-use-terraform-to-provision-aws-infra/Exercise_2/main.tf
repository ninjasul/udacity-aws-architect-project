provider "aws" {
  profile = var.profile
  region  = var.region_lambda
  alias   = "region-lambda"
}

data "archive_file" "greeting" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = var.output_path
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

resource "aws_internet_gateway" "igw" {
  provider = aws.region-lambda
  vpc_id   = aws_vpc.vpc_lambda.id
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
  description = "Allow all traffic to Lambda SG"
  vpc_id      = aws_vpc.vpc_lambda.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "lambda_route_table" {
  provider = aws.region-lambda
  vpc_id   = aws_vpc.vpc_lambda.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Lambda-RT"
  }
}

resource "aws_main_route_table_association" "set-lambda-default-rt-assoc" {
  provider       = aws.region-lambda
  vpc_id         = aws_vpc.vpc_lambda.id
  route_table_id = aws_route_table.lambda_route_table.id
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
    },
    {
        "Action": [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        "Effect": "Allow",
        "Resource": "*"
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
  runtime          = "python3.7"

  environment {
    variables = {
      greeting = "hello"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_iam_role_policy,
    aws_cloudwatch_log_group.greeting_log_group,
    aws_main_route_table_association.set-lambda-default-rt-assoc
  ]

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_subnet.id]
    security_group_ids = [aws_security_group.lambda-sg.id]
  }
}