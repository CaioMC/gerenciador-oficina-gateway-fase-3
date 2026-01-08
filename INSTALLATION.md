# 🚀 Guia de Instalação - API Gateway Infrastructure

Este documento descreve os passos para provisionar o AWS API Gateway com Terraform.

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter:

1. **Terraform** instalado (≥ v1.13.0)
   ```bash
   terraform version
   ```

2. **AWS CLI** instalado e configurado
   ```bash
   aws --version
   aws configure
   ```

3. **Credenciais AWS** com permissões para:
   - API Gateway
   - CloudWatch
   - IAM
   - S3 (para backend remoto)
   - DynamoDB (para locks)

4. **Cluster EKS** já provisionado (gerenciador-oficina-core)

5. **Network Load Balancer (NLB)** do EKS disponível

## 🔧 Passo 1: Clonar o Repositório

```bash
git clone <repository-url>
cd gerenciador-oficina-api-gateway-infra-fase-3
cd infra-api-gateway
```

## 🔑 Passo 2: Configurar Credenciais AWS

### Opção A: AWS CLI (Recomendado)

```bash
aws configure
```

Preencha com suas credenciais:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: us-east-1
- Default output format: json

### Opção B: Variáveis de Ambiente

```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## 📝 Passo 3: Configurar Variáveis

### 3.1 Copiar arquivo de exemplo

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3.2 Editar terraform.tfvars

```bash
vim terraform.tfvars
```

**Variáveis importantes:**

```hcl
# Endpoint do NLB (obter com comando abaixo)
nlb_endpoint = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"

# Rate limiting
rate_limit_requests = 5    # 5 requisições por minuto
burst_limit         = 10   # 10 requisições simultâneas
```

### 3.3 Obter Endpoint do NLB

```bash
# Listar todos os load balancers
aws elbv2 describe-load-balancers --region us-east-1

# Filtrar apenas o NLB do EKS
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].DNSName' \
  --output text
```

Copie o DNS Name e adicione em `terraform.tfvars`:

```hcl
nlb_endpoint = "k8s-gerenciador-1234567890.us-east-1.elb.amazonaws.com"
```

## 🏗️ Passo 4: Inicializar Terraform

```bash
terraform init
```

Isso irá:
- Baixar os providers necessários
- Configurar o backend remoto (S3 + DynamoDB)
- Criar o arquivo `.terraform.lock.hcl`

## ✅ Passo 5: Validar Configuração

```bash
terraform validate
```

Deve retornar:
```
Success! The configuration is valid.
```

## 📊 Passo 6: Visualizar Plano de Execução

```bash
terraform plan -out=tfplan
```

Revise os recursos que serão criados. Deve incluir:
- 1 API Gateway REST
- 1 API Key
- 1 Usage Plan
- 1 CloudWatch Log Group
- 1 IAM Role
- Várias métricas do CloudWatch

## 🚀 Passo 7: Aplicar Configuração

```bash
terraform apply tfplan
```

Ou diretamente:

```bash
terraform apply
```

Confirme digitando `yes` quando solicitado.

## ✨ Passo 8: Obter Outputs

Após o deploy bem-sucedido, obtenha as informações de saída:

```bash
terraform output
```

Ou específico:

```bash
# Endpoint do API Gateway
terraform output api_gateway_endpoint

# URL do Swagger UI
terraform output swagger_ui_url

# Informações de rate limiting
terraform output rate_limit_info
```

## 🧪 Passo 9: Testar o API Gateway

### 9.1 Acessar Swagger UI

```bash
# Obter endpoint
ENDPOINT=$(terraform output -raw api_gateway_endpoint)

# Acessar Swagger UI
echo "Acesse: ${ENDPOINT}/swagger-ui/index.html"
```

### 9.2 Testar Redirecionamento

```bash
# Deve redirecionar para /swagger-ui/index.html
curl -i https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/
```

### 9.3 Testar Rate Limiting

```bash
# Fazer 6 requisições rapidamente (limite é 5 por minuto)
for i in {1..6}; do
  curl -X GET https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/swagger-ui/index.html
  echo "Requisição $i"
done

# A 6ª requisição deve retornar 429 (Too Many Requests)
```

## 📊 Passo 10: Monitorar Logs

### 10.1 Ver logs em tempo real

```bash
# Obter nome do log group
LOG_GROUP=$(terraform output -raw cloudwatch_log_group_name)

# Acompanhar logs
aws logs tail $LOG_GROUP --follow
```

### 10.2 Filtrar por erros

```bash
LOG_GROUP=$(terraform output -raw cloudwatch_log_group_name)

aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR"
```

## 🔄 Passo 11: Atualizar Configuração

Se precisar atualizar variáveis:

```bash
# Editar terraform.tfvars
vim terraform.tfvars

# Planejar mudanças
terraform plan

# Aplicar mudanças
terraform apply
```

## 🗑️ Passo 12: Destruir Recursos (Opcional)

Para remover toda a infraestrutura:

```bash
terraform destroy
```

Confirme digitando `yes`.

## 🐛 Troubleshooting

### Erro: "Backend initialization required"

```bash
terraform init
```

### Erro: "Invalid credentials"

Verifique suas credenciais AWS:
```bash
aws sts get-caller-identity
```

### Erro: "NLB endpoint not found"

Verifique se o EKS está provisionado:
```bash
aws eks list-clusters --region us-east-1
```

### Erro: "API Gateway already exists"

```bash
# Listar API Gateways existentes
aws apigateway get-rest-apis

# Se necessário, destruir e recriar
terraform destroy
terraform apply
```

## 📚 Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [AWS CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)

## 💡 Dicas

1. **Use variáveis de ambiente** para credenciais em CI/CD
2. **Sempre revise o plano** antes de aplicar em produção
3. **Mantenha o state remoto** sincronizado em equipes
4. **Use tags** para organizar e rastrear custos
5. **Monitore os logs** regularmente

## 📞 Suporte

Para problemas ou dúvidas, consulte:
- Documentação do Terraform
- AWS Support
- GitHub Issues do projeto
