# infrastructure/modules/database/outputs.tf

output "dynamodb_table_name" {
  description = "El nombre de la tabla de DynamoDB."
  value       = aws_dynamodb_table.video_metadata.name
}

output "dynamodb_table_stream_arn" {
  description = "El ARN del stream de la tabla de DynamoDB."
  value       = aws_dynamodb_table.video_metadata.stream_arn
}

output "opensearch_endpoint" {
  description = "El endpoint del cluster de OpenSearch."
  value       = aws_opensearchserverless_collection.search_collection.collection_endpoint
}
