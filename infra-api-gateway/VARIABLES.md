# 📋 Documentação de Variáveis - API Gateway Infrastructure

## Variáveis Principais

### Projeto

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `project_name` | string | `gerenciador-oficina-core` | Nome do projeto |
| `environment` | string | `prod` | Ambiente de deployment (dev, staging, prod) |
| `aws_region` | string | `us-east-1` | Região AWS |

### API Gateway

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `api_gateway_name` | string | `gerenciador-oficina-api` | Nome do API Gateway |
| `api_stage_name` | string | `prod` | Nome do stage (prod, staging, dev) |

### Rate Limiting

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `rate_limit_requests` | number | `5` | Número máximo de requisições por minuto |
| `burst_limit` | number | `10` | Limite de requisições simultâneas |

### Backend (EKS)

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `nlb_endpoint` | string | `` | Endpoint do Network Load Balancer (EKS) |
| `nlb_port` | number | `80` | Porta do Network Load Balancer |

### CloudWatch

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `enable_cloudwatch_logs` | bool | `true` | Habilitar CloudWatch Logs |
| `cloudwatch_log_retention_days` | number | `30` | Retenção de logs em dias |

### CORS

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `enable_cors` | bool | `true` | Habilitar CORS |
| `cors_allowed_origins` | list(string) | `["*"]` | Origens CORS permitidas |
| `cors_allowed_methods` | list(string) | `["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]` | Métodos HTTP permitidos |
| `cors_allowed_headers` | list(string) | `["Content-Type", "Authorization", ...]` | Headers permitidos |

### Tags

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `tags` | map(string) | `{}` | Tags adicionais para recursos |

---

## Exemplos de Configuração

### Configuração Mínima

```hcl
# terraform.tfvars
nlb_endpoint = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"
```

### Configuração Padrão (Produção)

```hcl
# terraform.tfvars
project_name                  = "gerenciador-oficina-core"
environment                   = "prod"
aws_region                    = "us-east-1"
api_gateway_name              = "gerenciador-oficina-api"
api_stage_name                = "prod"
rate_limit_requests           = 5
burst_limit                   = 10
nlb_endpoint                  = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"
nlb_port                      = 80
enable_cloudwatch_logs        = true
cloudwatch_log_retention_days = 30
enable_cors                   = true

tags = {
  Project     = "gerenciador-oficina-core"
  Environment = "prod"
  Team        = "DevOps"
  ManagedBy   = "Terraform"
}
```

### Configuração de Desenvolvimento

```hcl
# terraform.tfvars
project_name                  = "gerenciador-oficina-core"
environment                   = "dev"
aws_region                    = "us-east-1"
api_gateway_name              = "gerenciador-oficina-api-dev"
api_stage_name                = "dev"
rate_limit_requests           = 100  # Limite maior para desenvolvimento
burst_limit                   = 50
nlb_endpoint                  = "k8s-gerenciador-dev-1234567890.us-east-1.elb.amazonaws.com"
cloudwatch_log_retention_days = 7    # Menos retenção

tags = {
  Project     = "gerenciador-oficina-core"
  Environment = "dev"
  Team        = "DevOps"
  ManagedBy   = "Terraform"
}
```

### Configuração com Rate Limiting Restritivo

```hcl
# terraform.tfvars
rate_limit_requests = 1    # 1 requisição por minuto
burst_limit         = 2    # 2 requisições simultâneas
```

---

## Obter Valores de Variáveis

### NLB Endpoint

```bash
# Listar todos os load balancers
aws elbv2 describe-load-balancers --region us-east-1

# Filtrar apenas o NLB do EKS
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].DNSName' \
  --output text

# Resultado
k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com
```

### Região AWS

```bash
# Obter região padrão
aws configure get region

# Listar regiões disponíveis
aws ec2 describe-regions --query 'Regions[*].RegionName' --output text
```

---

## Variáveis de Ambiente (CI/CD)

### GitHub Actions

```yaml
env:
  AWS_REGION: us-east-1
  TF_VAR_project_name: gerenciador-oficina-core
  TF_VAR_api_gateway_name: gerenciador-oficina-api
  TF_VAR_rate_limit_requests: 5
  TF_VAR_burst_limit: 10
```

### GitLab CI

```yaml
variables:
  AWS_REGION: us-east-1
  TF_VAR_project_name: gerenciador-oficina-core
  TF_VAR_api_gateway_name: gerenciador-oficina-api
```

### Terraform Cloud

```hcl
# Via interface web ou API
variable "nlb_endpoint" {
  type    = string
  default = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"
}
```

---

## Validação de Variáveis

### Validar Sintaxe

```bash
terraform validate
```

### Validar Valores

```bash
terraform plan -var-file=terraform.tfvars
```

### Listar Variáveis Usadas

```bash
terraform console
> var.rate_limit_requests
5
```

---

## Sensibilidade de Dados

### Variáveis Sensíveis

Algumas variáveis contêm dados sensíveis:

```hcl
# Não adicionar ao Git
terraform.tfvars

# Usar em CI/CD
export TF_VAR_nlb_endpoint="..."
```

### Outputs Sensíveis

```hcl
output "api_key_value" {
  sensitive = true  # Não exibir em logs
  value     = module.api_gateway.api_key_value
}
```

---

## Boas Práticas

1. **Use `terraform.tfvars.example`** como template
2. **Nunca commite `terraform.tfvars`** com dados sensíveis
3. **Use variáveis de ambiente** em CI/CD
4. **Documente valores customizados** em README
5. **Valide variáveis** antes de aplicar
6. **Use tags** para organizar recursos
7. **Mantenha valores padrão** sensatos

---

## Referências

- [Terraform Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Variable Definitions](https://www.terraform.io/docs/language/values/variables.html#variable-definitions)
- [Variable Validation](https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules)
