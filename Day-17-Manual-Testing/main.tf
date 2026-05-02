terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day17/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=main"

  cluster_name               = "webservers-day17"
  environment                = "dev"
  enable_autoscaling         = true
  enable_detailed_monitoring = true
  use_existing_vpc           = false
  server_port                = 80
  custom_tag                 = "day17-updated"
  active_environment         = "blue"
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}