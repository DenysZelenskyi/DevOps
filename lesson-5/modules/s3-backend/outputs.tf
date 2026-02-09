output "s3_bucket_id" {
  value = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.terraform_locks.arn
}