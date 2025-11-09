resource "aws_sqs_queue" "poc_infracost" {
  name                      = "fausto-poc-infracost"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  tags = {
    Project = "POC-Atlantis-Infracost"
  }
}

resource "aws_cloudwatch_log_group" "poc_logs" {
  name              = "/aws/fausto/poc-infracost"
  retention_in_days = 7

  tags = {
    Project     = "POC-Atlantis-Infracost"
    Environment = "Dev"
    Service     = "Logs"
    Owner       = "Fausto"
  }
}

resource "aws_instance" "meu_teste" {
  ami           = "ami-005e54dee72cc1d00"
  instance_type = "t3.micro"

  tags = {
    Environment = "Dev"
    Service     = "EC2-Test"
  }
}
