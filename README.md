# 🌐 Infraestrutura API Gateway com Terraform - Fase 3

[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure_as_Code-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-API_Gateway-orange?logo=amazon-aws)](https://aws.amazon.com/api-gateway/)
[![AWS](https://img.shields.io/badge/AWS-CloudWatch-blue?logo=amazon-aws)](https://aws.amazon.com/cloudwatch/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-Automation-black?logo=githubactions)](https://github.com/features/actions)

## 📋 Índice

- [Descrição do Propósito](#-descrição-do-propósito)
- [Tecnologias](#️-tecnologias)
- [Visão Geral da Arquitetura](#️-visão-geral-da-arquitetura)
- [Passos para Execução e Deploy](#-passos-para-execução-e-deploy)
- [Pipeline Automatizado (GitHub Actions)](#️-pipeline-automatizado-github-actions)
- [Repositórios Relacionados — Fase 3](#--repositórios-relacionados--fase-3)

## 🧩 Descrição do Propósito

Este repositório tem como objetivo **provisionar e gerenciar o AWS API Gateway** para a aplicação Gerenciador de Oficina, utilizando **Terraform** e pipelines automatizadas via **GitHub Actions**.

O projeto é responsável pela criação de:

- **API Gateway REST** para expor a aplicação Spring Boot;
- **Redirecionamento automático** de `/` para `/swagger-ui/index.html`;
- **Rate Limiting** de 5 requisições por minuto para proteção contra abuso;
- **CloudWatch Logs** para monitoramento e auditoria;
- **IAM Roles e Policies** para controle de acesso seguro;
- **Integração com EKS** via Network Load Balancer (NLB).

---

## 🛠️ Tecnologias

- **Terraform** - Gerenciador de Infraestrutura IaC
- **AWS** - Provedor de infraestrutura
- **AWS API Gateway** - Gateway de API REST
- **AWS CloudWatch** - Logs e monitoramento
- **AWS IAM** - Controle de acesso e permissões
- **AWS S3 + DynamoDB** - Armazena o `terraform.tfstate` e gerencia *locks*
- **GitHub Actions** - Automação CI/CD
- **GitHub** - Controle de versão

---

## 🏗️ Visão Geral da Arquitetura

A infraestrutura do projeto é provisionada utilizando Terraform, organizada de forma modular para facilitar a manutenção e o reuso, contendo os seguintes componentes:

- **API Gateway REST**: Expõe os endpoints da aplicação Spring Boot
- **Request/Response Models**: Define estrutura de requisições e respostas
- **Request Validators**: Valida requisições antes de encaminhar
- **Usage Plans**: Define rate limiting e quotas
- **API Keys**: Controla acesso aos endpoints
- **CloudWatch Logs**: Registra todas as requisições e respostas
- **IAM Roles**: Permissões para invocar o backend

### 📁 Estrutura

```plaintext
infra-api-gateway/
├── modules/          
│   ├── api_gateway/        # Configuração do API Gateway REST
│   ├── cloudwatch/         # Logs e monitoramento
│   └── iam/                # Roles e policies de acesso
├── main.tf                 # Arquivo principal que integra os módulos
├── variables.tf            # Variáveis principais
├── outputs.tf              # Outputs (endpoint, etc.)
├── providers.tf            # Configuração de providers
├── backend.tf              # Configuração do backend remoto
└── terraform.tfvars        # Valores das variáveis (exemplo)
```

---

## 🚀 Passos para Execução e Deploy

### 🔧 1. Pré-requisitos

- Terraform instalado (≥ v1.13.0)
- Conta AWS com permissões para criar recursos API Gateway, CloudWatch, IAM
- GitHub Actions configurado com os secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- Cluster EKS já provisionado (gerenciador-oficina-core)
- Network Load Balancer (NLB) do EKS disponível
- Criar um bucket S3 para o backend remoto do Terraform

### 🧠 2. Configuração local

```bash
cd infra-api-gateway

# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Visualizar plano de execução
terraform plan

# Aplicar configuração
terraform apply
```

Isso criará automaticamente:

- API Gateway REST com endpoints configurados
- Redirecionamento de `/` para `/swagger-ui/index.html`
- Rate limiting de 5 requisições por minuto
- CloudWatch Logs para auditoria
- IAM Roles e Policies necessárias

### 3. Obter Endpoint do API Gateway

Após o `terraform apply`, o endpoint será exibido em `outputs`. Exemplo:

```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod
```

Acesse:
```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/swagger-ui/index.html
```

## ⚙️ Pipeline Automatizado (GitHub Actions)

🚀 **terraform.yml**
- Executa após o merge na branch main
  - `terraform init`
  - `terraform validate`
  - `terraform plan -input=false -out=tfplan`
  - `terraform apply -auto-approve tfplan`

💣 **terraform-destroy.yml**
- Pode ser rodado manualmente via `workflow_dispatch`
- Executa `terraform destroy` com confirmação automática

---

## 📊 Rate Limiting

O API Gateway está configurado com:

- **Rate Limit**: 5 requisições por minuto por cliente
- **Burst Limit**: 10 requisições simultâneas
- **Throttle Settings**: Aplicado globalmente a todos os endpoints

Clientes que excederem o limite receberão resposta HTTP 429 (Too Many Requests).

---

## 🔍 Monitoramento e Logs

Todos os eventos são registrados no CloudWatch:

```bash
# Visualizar logs em tempo real
aws logs tail /aws/api-gateway/gerenciador-oficina-api --follow

# Filtrar por erros
aws logs filter-log-events \
  --log-group-name /aws/api-gateway/gerenciador-oficina-api \
  --filter-pattern "ERROR"
```

---

## 🔗 Repositórios Relacionados — Fase 3

A arquitetura do **Gerenciador de Oficina — Fase 3** é composta por múltiplos módulos independentes, cada um versionado em um repositório separado para facilitar a manutenção e o CI/CD.

| Módulo | Descrição | Repositório |
|:-------|:-----------|:--------------------------------------------------------|
| 🧱 **Core Application** | Aplicação principal responsável pelas regras de negócio, APIs REST e integração com os demais módulos. | [gerenciador-oficina-core-fase-3](https://github.com/thomaserick/gerenciador-oficina-core-fase-3) |
| ⚡ **Lambda Functions** | Conjunto de funções *serverless* para processamento assíncrono, notificações e automações event-driven. | [gerenciador-oficina-lambda-fase-3](https://github.com/thomaserick/gerenciador-oficina-lambda-fase-3) |
| ☸️ **Kubernetes Infrastructure** | Infraestrutura da aplicação no Kubernetes, incluindo manifests, deployments, ingress e autoscaling. | [gerenciador-oficina-k8s-infra-fase-3](https://github.com/thomaserick/gerenciador-oficina-k8s-infra-fase-3) |
| 🗄️ **Database Infrastructure** | Infraestrutura do banco de dados gerenciado (RDS PostgreSQL), versionada e automatizada via Terraform. | [gerenciador-oficina-db-infra-fase-3](https://github.com/thomaserick/gerenciador-oficina-db-infra-fase-3) |
| 🌐 **API Gateway Infrastructure** | Infraestrutura do API Gateway com rate limiting, redirecionamento e monitoramento via Terraform. | [gerenciador-oficina-api-gateway-infra-fase-3](https://github.com/thomaserick/gerenciador-oficina-api-gateway-infra-fase-3) |

> 🔍 Cada repositório é autônomo, mas integra-se ao **Core** por meio de pipelines e configurações declarativas (Terraform e CI/CD).
