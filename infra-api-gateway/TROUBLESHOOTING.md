# 🔧 Guia de Troubleshooting - API Gateway Infrastructure

## ❌ Erros Comuns e Soluções

### 1. Erro: "Backend initialization required"

**Mensagem**:
```
Error: Backend initialization required
```

**Causa**: O backend do Terraform não foi inicializado.

**Solução**:
```bash
cd infra-api-gateway
terraform init
```

---

### 2. Erro: "Invalid credentials"

**Mensagem**:
```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

**Causa**: Credenciais AWS não configuradas.

**Solução**:
```bash
# Verificar credenciais
aws sts get-caller-identity

# Se não funcionar, configurar
aws configure

# Ou usar variáveis de ambiente
export AWS_ACCESS_KEY_ID="sua-chave"
export AWS_SECRET_ACCESS_KEY="sua-senha"
export AWS_DEFAULT_REGION="us-east-1"
```

---

### 3. Erro: "NLB endpoint not found"

**Mensagem**:
```
Error: Invalid value for nlb_endpoint: NLB endpoint must be provided
```

**Causa**: Variável `nlb_endpoint` não foi configurada.

**Solução**:
```bash
# Encontrar o NLB do EKS
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].DNSName' \
  --output text

# Adicionar em terraform.tfvars
nlb_endpoint = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"

# Aplicar novamente
terraform apply
```

---

### 4. Erro: "API Gateway already exists"

**Mensagem**:
```
Error: Error creating REST API: BadRequestException: Invalid API name specified
```

**Causa**: API Gateway com o mesmo nome já existe.

**Solução - Opção A**: Usar nome diferente
```bash
# Editar terraform.tfvars
api_gateway_name = "gerenciador-oficina-api-v2"

# Aplicar
terraform apply
```

**Solução - Opção B**: Destruir e recriar
```bash
# Destruir recursos existentes
terraform destroy

# Aplicar novamente
terraform apply
```

---

### 5. Erro: "Access Denied" ao criar CloudWatch Logs

**Mensagem**:
```
Error: error creating CloudWatch Log Group: AccessDenied: User is not authorized to perform: logs:CreateLogGroup
```

**Causa**: Permissões insuficientes na AWS.

**Solução**:
```bash
# Verificar permissões do usuário IAM
aws iam get-user

# Adicionar política CloudWatch Logs ao usuário
# Consulte seu administrador AWS
```

---

### 6. Erro: "Backend S3 bucket not found"

**Mensagem**:
```
Error: error reading S3 Bucket: NotFound
```

**Causa**: Bucket S3 para backend não existe.

**Solução**:
```bash
# Criar bucket S3
aws s3 mb s3://gerenciador-oficina-fiap-caio --region us-east-1

# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket gerenciador-oficina-fiap-caio \
  --versioning-configuration Status=Enabled

# Criar tabela DynamoDB para locks
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

# Tentar novamente
terraform init
```

---

### 7. Erro: "Rate limit exceeded" durante deployment

**Mensagem**:
```
Error: error creating API Gateway: ThrottlingException: Rate exceeded
```

**Causa**: Muitas requisições à API AWS em pouco tempo.

**Solução**:
```bash
# Aguardar alguns minutos
sleep 60

# Tentar novamente
terraform apply
```

---

### 8. Erro: "Invalid proxy path"

**Mensagem**:
```
Error: Invalid proxy path: {proxy+} is not a valid path
```

**Causa**: Configuração incorreta do recurso proxy.

**Solução**:
```bash
# Verificar main.tf do módulo api_gateway
# Garantir que o recurso proxy está corretamente configurado

# Destruir e recriar
terraform destroy
terraform apply
```

---

## 🔍 Diagnóstico

### 1. Verificar Status do API Gateway

```bash
# Listar API Gateways
aws apigateway get-rest-apis

# Obter detalhes de um API Gateway específico
API_ID=$(terraform output -raw api_gateway_id)
aws apigateway get-rest-api --rest-api-id $API_ID
```

### 2. Verificar Logs do CloudWatch

```bash
# Listar log groups
aws logs describe-log-groups

# Ver logs em tempo real
LOG_GROUP=$(terraform output -raw cloudwatch_log_group_name)
aws logs tail $LOG_GROUP --follow

# Filtrar por status de erro
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "status >= 400"
```

### 3. Verificar Métricas do CloudWatch

```bash
# Listar métricas
aws cloudwatch list-metrics --namespace AWS/ApiGateway

# Obter estatísticas
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --start-time 2024-01-06T00:00:00Z \
  --end-time 2024-01-06T23:59:59Z \
  --period 3600 \
  --statistics Sum,Average
```

### 4. Verificar Rate Limiting

```bash
# Obter Usage Plan
USAGE_PLAN_ID=$(terraform output -raw usage_plan_id)
aws apigateway get-usage-plan --usage-plan-id $USAGE_PLAN_ID

# Ver throttle settings
aws apigateway get-usage-plan \
  --usage-plan-id $USAGE_PLAN_ID \
  --query 'throttleSettings'
```

### 5. Testar Conectividade com NLB

```bash
# Obter endpoint do NLB
NLB_ENDPOINT=$(grep nlb_endpoint terraform.tfvars | cut -d'"' -f2)

# Testar conectividade
curl -v http://$NLB_ENDPOINT:80/health

# Se falhar, verificar security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=eks-*" \
  --query 'SecurityGroups[*].[GroupId,GroupName]'
```

---

## 🧪 Testes

### 1. Teste de Redirecionamento

```bash
# Obter endpoint
ENDPOINT=$(terraform output -raw api_gateway_endpoint)

# Testar redirecionamento de /
curl -i $ENDPOINT/

# Deve retornar 301 ou 302 com Location header
```

### 2. Teste de Rate Limiting

```bash
ENDPOINT=$(terraform output -raw api_gateway_endpoint)

# Fazer 6 requisições rapidamente
for i in {1..6}; do
  echo "Requisição $i:"
  curl -w "Status: %{http_code}\n" $ENDPOINT/swagger-ui/index.html
  sleep 0.5
done

# A 6ª requisição deve retornar 429
```

### 3. Teste de Latência

```bash
ENDPOINT=$(terraform output -raw api_gateway_endpoint)

# Medir tempo de resposta
time curl $ENDPOINT/swagger-ui/index.html

# Verificar latência nos logs
aws logs filter-log-events \
  --log-group-name /aws/api-gateway/gerenciador-oficina-api \
  --query 'events[0].message' \
  --output text | jq '.integrationLatency'
```

---

## 📊 Monitoramento Contínuo

### 1. Dashboard CloudWatch

```bash
# Criar dashboard (manual via console AWS)
# Ou via CLI:

aws cloudwatch put-dashboard \
  --dashboard-name gerenciador-oficina-api \
  --dashboard-body file://dashboard.json
```

### 2. Alertas via SNS

```bash
# Criar tópico SNS
aws sns create-topic --name gerenciador-oficina-api-alerts

# Adicionar email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789:gerenciador-oficina-api-alerts \
  --protocol email \
  --notification-endpoint seu-email@example.com
```

### 3. Logs estruturados

```bash
# Filtrar por tipo de erro
aws logs filter-log-events \
  --log-group-name /aws/api-gateway/gerenciador-oficina-api \
  --filter-pattern "errorType != null"

# Contar erros por tipo
aws logs filter-log-events \
  --log-group-name /aws/api-gateway/gerenciador-oficina-api \
  --filter-pattern "status >= 400" \
  --query 'events | length(@)'
```

---

## 🔄 Recuperação de Falhas

### 1. Rollback de Alterações

```bash
# Ver histórico de state
aws s3 ls s3://gerenciador-oficina-fiap-caio/api-gateway/

# Restaurar versão anterior
aws s3api get-object \
  --bucket gerenciador-oficina-fiap-caio \
  --key api-gateway/terraform.tfstate \
  --version-id VERSION_ID \
  terraform.tfstate

# Aplicar estado anterior
terraform apply -state=terraform.tfstate
```

### 2. Recriar Recursos

```bash
# Marcar recurso para recriação
terraform taint aws_api_gateway_rest_api.main

# Aplicar
terraform apply

# Ou destruir e recriar
terraform destroy -target=aws_api_gateway_rest_api.main
terraform apply
```

### 3. Sincronizar State

```bash
# Verificar se state está sincronizado
terraform refresh

# Redownload state remoto
rm terraform.tfstate*
terraform init
```

---

## 📞 Contato e Suporte

- **AWS Support**: https://console.aws.amazon.com/support/
- **Terraform Community**: https://discuss.hashicorp.com/c/terraform/
- **GitHub Issues**: Abrir issue no repositório do projeto

---

## 📝 Checklist de Verificação

- [ ] Credenciais AWS configuradas
- [ ] Backend S3 e DynamoDB criados
- [ ] NLB endpoint do EKS obtido
- [ ] terraform.tfvars configurado
- [ ] terraform validate passou
- [ ] terraform plan revisado
- [ ] terraform apply executado com sucesso
- [ ] Outputs obtidos
- [ ] API Gateway acessível
- [ ] Redirecionamento funcionando
- [ ] Rate limiting testado
- [ ] Logs aparecendo no CloudWatch
- [ ] Alarmes configurados
- [ ] Documentação atualizada

---

## 🎯 Próximas Ações

Se o problema persistir:

1. Coletar logs detalhados
2. Documentar o erro exato
3. Verificar documentação AWS
4. Abrir issue no GitHub
5. Contatar suporte AWS
