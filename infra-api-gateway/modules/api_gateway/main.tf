# REST API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = "API Gateway para ${var.api_gateway_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# ✅ CORRIGIDO: Usar {proxy+} em vez de {proxy}
# {proxy+} captura todos os segmentos do path (greedy path)
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

  # Apenas o path é obrigatório
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# ✅ CORRIGIDO: Integração HTTP_PROXY com path mapping
# Agora o path é passado corretamente para o backend
resource "aws_api_gateway_integration" "proxy_http" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  
  # ✅ NOVO: Adicionar {proxy} ao URI para path mapping
  # Sem {proxy}: GET /prod/swagger-ui/index.html → GET /
  # Com {proxy}:  GET /prod/swagger-ui/index.html → GET /swagger-ui/index.html
  uri = "http://ab446b3b60bb64485b852c97f93691be-1844998745.us-east-1.elb.amazonaws.com/{proxy}"

  # ✅ NOVO: Mapear o path parameter
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [aws_api_gateway_method.proxy_any]
}

# ✅ Method Response para o proxy (200)
resource "aws_api_gateway_method_response" "proxy_response_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_any.http_method
  status_code = "200"
}

# ✅ Integration Response para o proxy (200)
# selection_pattern vazio = captura todos os status codes 2xx por padrão
resource "aws_api_gateway_integration_response" "proxy_response_200" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy_any.http_method
  status_code       = "200"
  selection_pattern = ""  # Padrão vazio = captura tudo
  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.proxy_http]
}

# ✅ Method Response para 4xx (Bad Request, Unauthorized, Forbidden, Not Found, etc)
resource "aws_api_gateway_method_response" "proxy_response_4xx" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_any.http_method
  status_code = "400"
}

# ✅ Integration Response para 4xx (400-499)
# selection_pattern = regex que captura 400-499
resource "aws_api_gateway_integration_response" "proxy_response_4xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy_any.http_method
  status_code       = "400"
  selection_pattern = "4\\d{2}"  # Regex: 400-499
  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.proxy_http]
}

# ✅ Method Response para 5xx (Internal Server Error, Bad Gateway, etc)
resource "aws_api_gateway_method_response" "proxy_response_5xx" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_any.http_method
  status_code = "500"
}

# ✅ Integration Response para 5xx (500-599)
# selection_pattern = regex que captura 500-599
resource "aws_api_gateway_integration_response" "proxy_response_5xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy_any.http_method
  status_code       = "500"
  selection_pattern = "5\\d{2}"  # Regex: 500-599
  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.proxy_http]
}

# Método GET para raíz (/) - redireciona para Swagger Docs
resource "aws_api_gateway_method" "root_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

# Integração MOCK para redirecionar
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
      requestId              = "$context.requestId"
      ip                     = "$context.identity.sourceIp"
      requestTime            = "$context.requestTime"
      httpMethod             = "$context.httpMethod"
      resourcePath           = "$context.resourcePath"
      status                 = "$context.status"
      protocol               = "$context.protocol"
      responseLength         = "$context.responseLength"
      integrationLatency     = "$context.integration.latency"
      integrationStatus      = "$context.integration.status"
      error                  = "$context.error.message"
      errorType              = "$context.error.messageString"
      integrationErrorMessage = "$context.integration.error"
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
      aws_api_gateway_method_response.proxy_response_200.id,
      aws_api_gateway_integration_response.proxy_response_200.id,
      aws_api_gateway_method_response.proxy_response_4xx.id,
      aws_api_gateway_integration_response.proxy_response_4xx.id,
      aws_api_gateway_method_response.proxy_response_5xx.id,
      aws_api_gateway_integration_response.proxy_response_5xx.id,
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root_redirect.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.proxy_http,
    aws_api_gateway_method_response.proxy_response_200,
    aws_api_gateway_integration_response.proxy_response_200,
    aws_api_gateway_method_response.proxy_response_4xx,
    aws_api_gateway_integration_response.proxy_response_4xx,
    aws_api_gateway_method_response.proxy_response_5xx,
    aws_api_gateway_integration_response.proxy_response_5xx,
    aws_api_gateway_integration.root_redirect,
    aws_api_gateway_integration_response.root_redirect_response,
    aws_api_gateway_method_response.root_redirect_method_response,
  ]
}