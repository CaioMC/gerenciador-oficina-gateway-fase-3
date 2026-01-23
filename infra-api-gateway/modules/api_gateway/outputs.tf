output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_name" {
  description = "Nome do API Gateway"
  value       = aws_api_gateway_rest_api.main.name
}

output "api_gateway_endpoint" {
  description = "Endpoint do API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_key_id" {
  description = "ID da API Key"
  value       = aws_api_gateway_api_key.main.id
}

output "api_key_value" {
  description = "Valor da API Key (sensível)"
  value       = aws_api_gateway_api_key.main.value
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID do Usage Plan"
  value       = aws_api_gateway_usage_plan.main.id
}

output "stage_name" {
  description = "Nome do stage"
  value       = aws_api_gateway_stage.main.stage_name
}