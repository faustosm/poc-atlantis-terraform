terraform {
  backend "s3" {
    bucket = "var.bucket_name"
    key    = "global/terraform.tfstate"
    region = "var.aws_region"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}