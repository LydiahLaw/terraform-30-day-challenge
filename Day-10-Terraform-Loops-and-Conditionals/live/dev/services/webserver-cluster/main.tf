terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day10/dev/services/webserver-cluster/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=v0.0.3"

  cluster_name       = "webservers-dev"
  environment        = "dev"
  enable_autoscaling = false
  min_size           = 2
  max_size           = 4
  server_port        = 80
}