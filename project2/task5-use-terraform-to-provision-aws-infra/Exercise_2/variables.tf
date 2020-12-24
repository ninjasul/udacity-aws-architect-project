# TODO: Define the variable for aws_region
variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "lambda_function_name" {
  default = "greeting"
}

variable "output_path" {
  type    = string
  default = "outputs/greeting_lambda.zip"
}



