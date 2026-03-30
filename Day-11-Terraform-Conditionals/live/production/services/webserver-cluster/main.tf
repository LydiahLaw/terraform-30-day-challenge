terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day11/production/services/webserver-cluster/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=v0.0.4"

  cluster_name               = "webservers-production"
  environment                = "production"
  enable_autoscaling         = true
  enable_detailed_monitoring = true
  use_existing_vpc           = false
  server_port                = 80
  custom_tag                 = "day11-production"
}