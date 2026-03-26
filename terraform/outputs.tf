output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/incidents"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.incidents.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.incident_handler.function_name
}

output "custom_domain_endpoint" {
  description = "Custom domain API endpoint"
  value       = "https://api.project2.sergipratmerin.com/incidents"
}