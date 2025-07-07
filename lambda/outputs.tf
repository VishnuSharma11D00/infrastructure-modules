output "lambda_details" {
  value = {
    for key, lambda in aws_lambda_function.lambda : key => {
      arn  = lambda.arn
      name = lambda.function_name
    }
  }
}