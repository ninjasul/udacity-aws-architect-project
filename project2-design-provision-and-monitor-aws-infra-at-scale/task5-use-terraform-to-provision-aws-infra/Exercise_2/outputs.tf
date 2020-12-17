# TODO: Define the output variable for the lambda function.
output "lambda_greeting_id" {
  value = aws_lambda_function.greeting.id
}