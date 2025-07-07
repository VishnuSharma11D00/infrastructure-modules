variable "lambda_functions" {
  type = map(object({
    name                  = string
    zip_file              = string
    tagValue              = string
    policy_name           = string
    environment_variables = map(string)
    policy_document       = any
  }))
}

variable "env" {
  type = string
}
