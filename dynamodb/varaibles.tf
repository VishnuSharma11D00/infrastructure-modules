variable "dynamodb_tables" {
  type = map(object({
    name = string
    partition_key = object({
      name = string
      type = string
    })
    sort_key = optional(object({
      name = string
      type = string
    }))
    tagValue = string
  }))
}

variable "env" {
  type = string
}
