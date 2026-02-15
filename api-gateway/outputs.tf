output "api_urls" {
  value = {
    for key, resource in aws_api_gateway_resource.resource : key => "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${var.env}${aws_api_gateway_resource.resource[key].path}"
  }
}
