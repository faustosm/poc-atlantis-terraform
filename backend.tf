terraform {
  backend "s3" {
<<<<<<< HEAD
    bucket = "var.bucket_name"
    key    = "global/terraform.tfstate"
    region = "var.aws_region"
=======
    bucket = "poc-atlantis-terraform"
    key    = "global/terraform.tfstate"
    region = "sa-east-1"
>>>>>>> infracost-test
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}