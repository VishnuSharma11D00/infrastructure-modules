locals {
  common_tags = {
    Terraform = var.env
  }
}

resource "aws_dynamodb_table" "tf_db_table" {
  for_each = var.dynamodb_tables

  name         = "${var.env}-${each.value.name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.partition_key.name
  range_key    = try(each.value.sort_key.name, null)

  attribute {
    name = each.value.partition_key.name
    type = each.value.partition_key.type
  }

  dynamic "attribute" {
    for_each = each.value.sort_key != null ? [each.value.sort_key] : []
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  tags = merge(local.common_tags, {
    App = each.value.tagValue
  })
}
