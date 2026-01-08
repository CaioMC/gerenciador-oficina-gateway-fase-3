variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "gerenciador-oficina-core"
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "api_gateway_name" {
  description = "Nome do API Gateway"
  type        = string
  default     = "gerenciador-oficina-api"
}

variable "api_stage_name" {
  description = "Nome do stage do API Gateway"
  type        = string
  default     = "prod"
}

variable "rate_limit_requests" {
  description = "Número máximo de requisições por minuto"
  type        = number
  default     = 5
}

variable "burst_limit" {
  description = "Limite de requisições simultâneas"
  type        = number
  default     = 10
}

variable "nlb_endpoint" {
  description = "Endpoint do Network Load Balancer (EKS)"
  type        = string
  default     = ""
}

variable "nlb_port" {
  description = "Porta do Network Load Balancer"
  type        = number
  default     = 80
}

variable "enable_cloudwatch_logs" {
  description = "Habilitar CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Retenção de logs em dias"
  type        = number
  default     = 30
}

variable "enable_cors" {
  description = "Habilitar CORS"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Origens CORS permitidas"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "Métodos HTTP CORS permitidos"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "Headers CORS permitidos"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
}

variable "tags" {
  description = "Tags adicionais para recursos"
  type        = map(string)
  default     = {}
}
