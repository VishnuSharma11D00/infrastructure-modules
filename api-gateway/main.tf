locals {
  common_tags = {
    Terraform = var.env
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.env}-${var.api_name}"
  tags = local.common_tags
}

resource "aws_api_gateway_resource" "resource" {
  for_each = var.api_configurations

  path_part   = each.value.path_part_name
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  for_each = var.api_configurations

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource[each.key].id
  http_method   = each.value.api_method
  authorization = "NONE"

  request_parameters = try({
    for key, value in each.value.query_string_parameters : "method.request.querystring.${key}" => value
  }, {})
}

resource "aws_api_gateway_integration" "integration" {
  for_each = var.api_configurations

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.method[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS"
  # Here the type should be AWS, not AWS_PROXY for lambda integration with CORS
  uri = "arn:aws:apigateway:${var.my_region}:lambda:path/2015-03-31/functions/${each.value.lambda_function_arn}/invocations"

  request_templates = {
    "application/json" = each.value.mapping_template_body
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  for_each = var.api_configurations

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.method[each.key].http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_integration.integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${var.cors_allowed_origin}'"
  }
}

resource "aws_api_gateway_method_response" "method_response" {
  for_each = var.api_configurations

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.method[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  depends_on = [aws_api_gateway_method.method]
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  for_each = var.api_configurations

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.my_region}:${var.account_Id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method[each.key].http_method}${aws_api_gateway_resource.resource[each.key].path}"
}

# CORS

resource "aws_api_gateway_method" "cors_options" {
  for_each = var.api_configurations

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  for_each = var.api_configurations

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  for_each = var.api_configurations

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_integration.cors_integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'${aws_api_gateway_method.method[each.key].http_method},OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }
}

resource "aws_api_gateway_method_response" "cors_method_response" {
  for_each = var.api_configurations

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [aws_api_gateway_integration.integration, aws_api_gateway_integration.cors_integration]

  triggers = {
    redeployment = sha1(jsonencode({
      api_configurations = var.api_configurations
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.env
  tags          = local.common_tags
}
