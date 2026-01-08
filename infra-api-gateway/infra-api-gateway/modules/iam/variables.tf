variable "api_gateway_name" {
  description = "Nome do API Gateway"
  type        = string
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
