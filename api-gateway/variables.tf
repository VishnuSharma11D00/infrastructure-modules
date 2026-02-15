variable "env" {
  type = string
}

variable "api_name" {
  type = string
}

variable "cors_allowed_origin" {
  type = string
}

variable "api_configurations" {
  type = map(object({
    path_part_name          = string
    api_method              = string
    lambda_function_name    = string
    lambda_function_arn     = string
    query_string_parameters = optional(map(bool))
    mapping_template_body   = optional(string, "$input.json('$')")
  }))
}
