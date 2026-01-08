output "api_gateway_endpoint" {
  description = "Endpoint do API Gateway"
  value       = module.api_gateway.api_gateway_endpoint
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_name" {
  description = "Nome do API Gateway"
  value       = module.api_gateway.api_gateway_name
}

output "api_key_id" {
  description = "ID da API Key"
  value       = module.api_gateway.api_key_id
}

output "api_key_value" {
  description = "Valor da API Key (sensível)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID do Usage Plan com rate limiting"
  value       = module.api_gateway.usage_plan_id
}

output "stage_name" {
  description = "Nome do stage"
  value       = module.api_gateway.stage_name
}

output "cloudwatch_log_group_name" {
  description = "Nome do CloudWatch Log Group"
  value       = module.cloudwatch.log_group_name
}

output "cloudwatch_error_log_group_name" {
  description = "Nome do CloudWatch Log Group de erros"
  value       = module.cloudwatch.error_log_group_name
}

output "iam_role_arn" {
  description = "ARN da IAM Role do API Gateway"
  value       = module.iam.api_gateway_role_arn
}

output "swagger_ui_url" {
  description = "URL para acessar o Swagger UI"
  value       = "${module.api_gateway.api_gateway_endpoint}/swagger-ui/index.html"
}

output "rate_limit_info" {
  description = "Informações sobre rate limiting"
  value = {
    requests_per_minute = var.rate_limit_requests
    burst_limit         = var.burst_limit
    quota_per_day       = var.rate_limit_requests * 60 * 24
  }
}
