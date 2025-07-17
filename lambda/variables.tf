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

variable "prefix" {
  type        = string
  description = "Add prefix to lambda name so that you won't create a function with the same name"
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}
