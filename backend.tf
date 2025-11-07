resource "aws_sqs_queue" "poc_infracost" {
  name = "fausto-poc-infracost"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  delay_seconds              = 0

  tags = {
    Project     = "POC-Atlantis-Infracost"
    Environment = "dev"
    Owner       = "Fausto"
  }
}
