output "api_gateway_role_arn" {
  description = "ARN da IAM Role do API Gateway"
  value       = aws_iam_role.api_gateway_role.arn
}

output "api_gateway_role_name" {
  description = "Nome da IAM Role do API Gateway"
  value       = aws_iam_role.api_gateway_role.name
}
