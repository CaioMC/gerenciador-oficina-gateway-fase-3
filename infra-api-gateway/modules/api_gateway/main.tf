# REST API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = "API Gateway para ${var.api_gateway_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Resource para proxy (captura todos os paths incluindo raiz)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Método ANY para proxy (todos os métodos HTTP)
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integração HTTP para o backend (NLB)
resource "aws_api_gateway_integration" "proxy_http" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP"
  integration_http_method = "ANY"
  uri                     = "http://ab3aec5d75ac942698ace6997271b40a-177148928.us-east-1.elb.amazonaws.com:8081/{proxy+}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [aws_api_gateway_method.proxy_any]
}

# Response da integração para status 200 (padrão)
resource "aws_api_gateway_integration_response" "proxy_response_200" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy_any.http_method
  status_code       = "200"
  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.proxy_http]
}

# Method Response para 200
resource "aws_api_gateway_method_response" "proxy_response_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_any.http_method
  status_code = "200"
}

# Método GET para raiz (/) - redireciona para Swagger UI
resource "aws_api_gateway_method" "root_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

# Integração MOCK para redirecionar / para /swagger-ui/index.html
resource "aws_api_gateway_integration" "root_redirect" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = aws_api_gateway_method.root_get.http_method
  type             = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 301}"
  }
}

# Response para redirecionar (status 301)
resource "aws_api_gateway_integration_response" "root_redirect_response" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_rest_api.main.root_resource_id
  http_method       = aws_api_gateway_method.root_get.http_method
  status_code       = "301"
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Location" = "'${var.swagger_ui_path}'"
  }

  depends_on = [aws_api_gateway_integration.root_redirect]
}

# Method Response para redirecionar (status 301)
resource "aws_api_gateway_method_response" "root_redirect_method_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "301"

  response_parameters = {
    "method.response.header.Location" = true
  }
}

# API Key para controle de acesso
resource "aws_api_gateway_api_key" "main" {
  name        = "${var.api_gateway_name}-key"
  description = "API Key para ${var.api_gateway_name}"
  enabled     = true

  tags = var.tags
}

# Usage Plan para rate limiting
resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.api_gateway_name}-usage-plan"
  description = "Usage plan com rate limiting para ${var.api_gateway_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    burst_limit = var.burst_limit
    rate_limit  = var.rate_limit_requests
  }

  quota_settings {
    limit  = var.rate_limit_requests * 60 * 24 # Quota diária
    period = "DAY"
  }

  tags = var.tags
}

# Associar API Key ao Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}

# CloudWatch Role para logging
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}

# Stage de produção
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = var.cloudwatch_log_group_arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integration.latency"
      error          = "$context.error.message"
      errorType      = "$context.error.messageString"
    })
  }

  variables = {
    "environment" = var.stage_name
  }

  tags = var.tags

  depends_on = [aws_api_gateway_account.main]
}

# Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.proxy_http.id,
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root_redirect.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.proxy_http,
    aws_api_gateway_integration_response.proxy_response_200,
    aws_api_gateway_method_response.proxy_response_200,
    aws_api_gateway_integration.root_redirect,
    aws_api_gateway_integration_response.root_redirect_response,
    aws_api_gateway_method_response.root_redirect_method_response,
  ]
}