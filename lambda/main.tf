locals {
  common_tags = {
    Terraform = var.env
  }
}

resource "aws_lambda_function" "lambda" {
  for_each = var.lambda_functions

  filename      = each.value.zip_file
  function_name = "${var.env}-${each.value.name}"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec[each.key].arn

  environment {
    variables = each.value.environment_variables
  }

  tags = merge(local.common_tags, {
    App = each.value.tagValue
  })
}

resource "aws_iam_role" "lambda_exec" {
  for_each = var.lambda_functions

  name        = "${var.env}-${each.value.name}-exec-role"
  description = "Execution role for ${var.env}-${each.value.name} Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "lambda_policy" {
  for_each = var.lambda_functions

  name   = "${var.env}-${each.value.policy_name}"
  policy = jsonencode(each.value.policy_document)

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  for_each = var.lambda_functions

  role       = aws_iam_role.lambda_exec[each.key].name
  policy_arn = aws_iam_policy.lambda_policy[each.key].arn
}


# Create a separate policy for CloudWatch logs
resource "aws_iam_policy" "lambda_logs_policy" {
  for_each = var.lambda_functions

  name   = "${var.env}-${each.value.name}-logs-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${var.env}-${each.value.name}:*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach the CloudWatch logs policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  for_each = var.lambda_functions

  role       = aws_iam_role.lambda_exec[each.key].name
  policy_arn = aws_iam_policy.lambda_logs_policy[each.key].arn
}