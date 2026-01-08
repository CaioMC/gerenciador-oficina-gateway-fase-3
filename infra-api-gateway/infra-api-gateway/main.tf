# Módulo IAM
module "iam" {
  source = "./modules/iam"

  api_gateway_name = var.api_gateway_name
  tags = merge(
    var.tags,
    {
      Name        = var.api_gateway_name
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Módulo CloudWatch
module "cloudwatch" {
  source = "./modules/cloudwatch"

  api_gateway_name      = var.api_gateway_name
  log_retention_days    = var.cloudwatch_log_retention_days
  rate_limit_threshold  = var.rate_limit_requests * 10
  tags                  = merge(var.tags, { Name = var.api_gateway_name })
}

# Módulo API Gateway
module "api_gateway" {
  source = "./modules/api_gateway"

  api_gateway_name         = var.api_gateway_name
  stage_name               = var.api_stage_name
  nlb_endpoint             = var.nlb_endpoint
  rate_limit_requests      = var.rate_limit_requests
  burst_limit              = var.burst_limit
  swagger_ui_path          = "/swagger-ui/index.html"
  cloudwatch_role_arn      = module.iam.api_gateway_role_arn
  cloudwatch_log_group_arn = module.cloudwatch.log_group_arn
  tags                     = merge(var.tags, { Name = var.api_gateway_name })

  depends_on = [module.iam, module.cloudwatch]
}
