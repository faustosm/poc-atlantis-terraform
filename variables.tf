# região onde os recursos serão criados

variable aws_region {
  type        = string
  default     = "sa-east-1"
  description = "Região AWS onde os recursos serão criados"
}

# nome do bucket S3 para armazenar o estado do Terraform
variable bucket_name {
  type        = string
  default     = "poc-atlantis-terraform"
  description = "Nome do bucket S3 para armazenar o estado do Terraform"
}

variable dynamodb_table {
  type        = string
  default     = "terraform-locks"
  description = "Tabela do DynamoDB para bloqueio do state"
}
