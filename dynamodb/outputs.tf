output "table_details" {
  value = {
    for table_name, table in aws_dynamodb_table.tf_db_table : table_name => {
      arn  = table.arn
      name = table.name
    }
  }
}
