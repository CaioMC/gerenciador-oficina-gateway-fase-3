output "log_group_name" {
  description = "Nome do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

output "log_group_arn" {
  description = "ARN do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.api_gateway_logs.arn
}

output "error_log_group_name" {
  description = "Nome do CloudWatch Log Group de erros"
  value       = aws_cloudwatch_log_group.api_gateway_errors.name
}
