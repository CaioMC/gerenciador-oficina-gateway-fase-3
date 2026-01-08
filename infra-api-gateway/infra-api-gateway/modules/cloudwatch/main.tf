# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${var.api_gateway_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Log Group para erros
resource "aws_cloudwatch_log_group" "api_gateway_errors" {
  name              = "/aws/api-gateway/${var.api_gateway_name}-errors"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Métrica customizada para rate limiting
resource "aws_cloudwatch_metric_alarm" "rate_limit_exceeded" {
  alarm_name          = "${var.api_gateway_name}-rate-limit-exceeded"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.rate_limit_threshold
  alarm_description   = "Alerta quando o rate limit é excedido"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = var.tags
}

# Métrica para erros 4xx
resource "aws_cloudwatch_metric_alarm" "client_errors" {
  alarm_name          = "${var.api_gateway_name}-client-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alerta para erros de cliente (4xx)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = var.tags
}

# Métrica para erros 5xx
resource "aws_cloudwatch_metric_alarm" "server_errors" {
  alarm_name          = "${var.api_gateway_name}-server-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alerta para erros de servidor (5xx)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = var.tags
}
