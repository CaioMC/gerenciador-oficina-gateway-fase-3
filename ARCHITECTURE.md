# 🏗️ Arquitetura - API Gateway Infrastructure

## 📊 Visão Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet / Clientes                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS API Gateway (REST)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ GET /              → Redireciona para /swagger-ui/...    │  │
│  │ ANY /{proxy+}      → Encaminha para o backend (EKS)      │  │
│  │ Rate Limit: 5 req/min                                    │  │
│  │ Burst Limit: 10 req simultâneas                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Network Load Balancer (EKS)                    │
│              (gerenciador-oficina-core-nlb)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EKS Cluster (Kubernetes)                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Pod: gerenciador-oficina-core (Spring Boot)             │  │
│  │ Porta: 8081                                              │  │
│  │ Replicas: 2-10 (Auto Scaling)                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RDS PostgreSQL (Database)                    │
│              (gerenciador-oficina-core)                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   CloudWatch (Monitoramento)                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Logs: /aws/api-gateway/gerenciador-oficina-api          │  │
│  │ Métricas: Requisições, Erros, Rate Limit                │  │
│  │ Alarms: 4xx, 5xx, Rate Limit Exceeded                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🔌 Componentes

### 1. API Gateway REST

**Responsabilidade**: Expor a aplicação Spring Boot via HTTP(S)

**Recursos**:
- **Endpoint Base**: `https://{api-id}.execute-api.us-east-1.amazonaws.com/prod`
- **Redirecionamento**: `/` → `/swagger-ui/index.html`
- **Proxy**: `/{proxy+}` → Encaminha para o NLB

**Métodos HTTP Suportados**:
- GET, POST, PUT, DELETE, PATCH, OPTIONS

### 2. Rate Limiting (Usage Plan)

**Responsabilidade**: Proteger o backend contra abuso

**Configuração**:
- **Rate Limit**: 5 requisições por minuto
- **Burst Limit**: 10 requisições simultâneas
- **Quota Diária**: 7.200 requisições (5 × 60 × 24)

**Resposta ao Exceder Limite**:
```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json

{
  "message": "Rate exceeded"
}
```

### 3. CloudWatch Logs

**Responsabilidade**: Auditoria e monitoramento

**Log Groups**:
- `/aws/api-gateway/gerenciador-oficina-api` - Logs gerais
- `/aws/api-gateway/gerenciador-oficina-api-errors` - Logs de erro

**Campos Registrados**:
```json
{
  "requestId": "abc123def456",
  "ip": "203.0.113.45",
  "requestTime": "2024-01-06T21:30:00Z",
  "httpMethod": "GET",
  "resourcePath": "/swagger-ui/index.html",
  "status": 200,
  "protocol": "HTTP/1.1",
  "responseLength": 5234,
  "integrationLatency": 45,
  "error": null,
  "errorType": null
}
```

### 4. CloudWatch Alarms

**Responsabilidade**: Alertar sobre anomalias

| Alarme | Condição | Ação |
|--------|----------|------|
| Rate Limit Exceeded | > 50 req/min | Notificar |
| Client Errors (4xx) | > 10 em 5 min | Notificar |
| Server Errors (5xx) | > 5 em 5 min | Notificar |

### 5. IAM Roles e Policies

**Responsabilidade**: Controle de acesso

**Role**: `gerenciador-oficina-api-role`

**Policies**:
- CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents
- ELB: DescribeLoadBalancers, DescribeTargetGroups, DescribeTargetHealth

### 6. API Keys

**Responsabilidade**: Controle de acesso por cliente

**Características**:
- Chave única por cliente
- Associada a Usage Plan
- Pode ser rotacionada

## 🔄 Fluxo de Requisição

```
1. Cliente faz requisição
   └─ GET https://api.example.com/swagger-ui/index.html

2. API Gateway recebe
   └─ Valida API Key (se necessário)
   └─ Verifica Rate Limit

3. Rate Limit OK?
   ├─ NÃO → Retorna 429 (Too Many Requests)
   └─ SIM → Continua

4. Rota para o recurso
   ├─ GET / → Redireciona para /swagger-ui/index.html
   └─ ANY /{proxy+} → Encaminha para NLB

5. NLB encaminha para EKS
   └─ Pod Spring Boot processa

6. Resposta retorna
   └─ API Gateway registra em CloudWatch
   └─ Retorna ao cliente

7. CloudWatch monitora
   └─ Registra métricas
   └─ Verifica alarmes
```

## 📊 Integração com EKS

### Descoberta de Serviço

O API Gateway se conecta ao EKS através do **Network Load Balancer (NLB)**:

```bash
# Obter NLB do EKS
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].DNSName' \
  --output text

# Resultado
k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com
```

### Configuração do Terraform

```hcl
variable "nlb_endpoint" {
  default = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"
}

resource "aws_api_gateway_integration" "proxy_http" {
  uri = "http://${var.nlb_endpoint}:{proxy+}"
}
```

## 🔐 Segurança

### 1. HTTPS/TLS

- Certificado SSL/TLS gerenciado pela AWS
- Domínio: `{api-id}.execute-api.us-east-1.amazonaws.com`

### 2. Rate Limiting

- Proteção contra DDoS
- Limite por cliente via API Key
- Burst limit para picos legítimos

### 3. Logging e Auditoria

- Todos os eventos registrados em CloudWatch
- Retenção: 30 dias (configurável)
- Filtros para análise de segurança

### 4. IAM

- Role específica para API Gateway
- Permissões mínimas necessárias
- Auditoria via CloudTrail

## 📈 Escalabilidade

### API Gateway

- **Escalabilidade Automática**: AWS gerencia automaticamente
- **Limite Padrão**: 10.000 requisições/segundo
- **Limite Customizável**: Contatar AWS Support

### Rate Limiting

- **Por Cliente**: Aplicado via Usage Plan + API Key
- **Global**: Pode ser configurado em throttle settings

### Backend (EKS)

- **Auto Scaling**: HPA (Horizontal Pod Autoscaler)
- **Réplicas**: 2-10 pods conforme carga
- **Recursos**: CPU e Memória configuráveis

## 💰 Custo

### Componentes Cobrados

| Componente | Preço | Observação |
|-----------|-------|-----------|
| API Gateway | $3.50 por milhão de requisições | + $0.09 por GB de dados transferidos |
| CloudWatch Logs | $0.50 por GB ingerido | + $0.03 por GB armazenado |
| CloudWatch Alarms | $0.10 por alarme/mês | - |

### Estimativa Mensal

Considerando 5 req/min × 60 min × 24h × 30 dias = 216.000 requisições/mês:

- API Gateway: ~$0.76
- CloudWatch Logs: ~$2-5 (depende do volume)
- **Total**: ~$3-6/mês

## 🔧 Manutenção

### Backup e Recuperação

- **State**: Armazenado em S3 com versionamento
- **Logs**: Retenção automática de 30 dias
- **Configuração**: Versionada no Git

### Atualizações

```bash
# Atualizar Terraform
terraform get -update

# Validar mudanças
terraform plan

# Aplicar atualizações
terraform apply
```

### Monitoramento

```bash
# Verificar saúde
aws apigateway get-rest-api --rest-api-id {api-id}

# Ver métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --start-time 2024-01-06T00:00:00Z \
  --end-time 2024-01-06T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## 🚀 Próximos Passos

1. **Domínio Customizado**: Usar Route 53 + ACM
2. **WAF**: Adicionar AWS WAF para proteção adicional
3. **Caching**: Implementar CloudFront para cache
4. **Analytics**: Integrar com Kinesis para análise em tempo real
5. **Autenticação**: Adicionar OAuth/OpenID Connect

## 📚 Referências

- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Terraform AWS API Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)
- [AWS CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
