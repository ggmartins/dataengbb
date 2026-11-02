output "endpoint" {
  description = "mTLS-protected hello endpoint."
  value       = "https://${var.domain_name}/hello"
}

output "lambda_function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.hello.function_name
}

output "api_id" {
  description = "HTTP API ID. Its default execute-api endpoint is disabled."
  value       = aws_apigatewayv2_api.api.id
}
