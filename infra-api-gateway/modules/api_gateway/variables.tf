variable "api_gateway_name" {
  description = "Nome do API Gateway"
  type        = string
  default = "gerenciador-oficina-api-gateway"
}

variable "stage_name" {
  description = "Nome do stage"
  type        = string
  default     = "prod"
}

variable "nlb_endpoint" {
  description = "Endpoint do Network Load Balancer"
  default = "ab3aec5d75ac942698ace6997271b40a-177148928.us-east-1.elb.amazonaws.com"
  type        = string
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

variable "swagger_ui_path" {
  description = "Caminho para redirecionar /"
  type        = string
  default     = "/swagger-ui/index.html"
}

variable "cloudwatch_role_arn" {
  description = "ARN da role do CloudWatch"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN do log group do CloudWatch"
  type        = string
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
