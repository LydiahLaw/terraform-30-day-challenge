provider "aws" {
  region = "eu-central-1"
}

data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = "lydiah-terraform-state-bucket"
    key    = "environments/dev/terraform.tfstate"
    region = "eu-central-1"
  }
}

output "dev_instance_id" {
  value = data.terraform_remote_state.dev.outputs.instance_id
}

output "dev_environment" {
  value = data.terraform_remote_state.dev.outputs.environment
}