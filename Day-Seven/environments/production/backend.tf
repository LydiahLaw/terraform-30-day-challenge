terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "environments/production/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}