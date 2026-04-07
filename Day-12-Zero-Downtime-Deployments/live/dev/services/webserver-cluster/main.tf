terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day12/dev/services/webserver-cluster/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=v1.0.0"

  cluster_name               = "webservers-dev"
  environment                = "dev"
  enable_autoscaling         = false
  enable_detailed_monitoring = false
  use_existing_vpc           = false
  server_port                = 80
  custom_tag                 = "day12-dev"
  active_environment         = "blue"
}