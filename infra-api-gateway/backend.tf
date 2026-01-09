terraform {
  backend "s3" {
    bucket         = "gerenciador-oficina-fiap"
    key            = "api-gateway/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
