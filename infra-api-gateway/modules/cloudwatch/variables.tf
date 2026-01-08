variable "api_gateway_name" {
  description = "Nome do API Gateway"
  type        = string
}

variable "log_retention_days" {
  description = "Retenção de logs em dias"
  type        = number
  default     = 30
}

variable "rate_limit_threshold" {
  description = "Limite de requisições para alerta"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
