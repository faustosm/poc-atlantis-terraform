terraform {
  backend "s3" {
    bucket         = "poc-atlantis-terraform"
    key            = "global/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
