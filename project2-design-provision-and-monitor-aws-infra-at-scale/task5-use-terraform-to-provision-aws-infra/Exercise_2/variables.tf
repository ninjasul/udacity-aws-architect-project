# TODO: Define the variable for aws_region
variable "profile" {
  type    = string
  default = "default"
}

variable "region_lambda" {
  type    = string
  default = "ap-northeast-2"
}

variable "lambda_function_name" {
  default = "greeting"
}

data "archive_file" "greeting" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = var.output_path
}



