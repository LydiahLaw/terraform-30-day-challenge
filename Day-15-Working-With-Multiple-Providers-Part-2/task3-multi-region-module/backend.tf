terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day15/task3/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  alias  = "primary"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "replica"
  region = "eu-west-1"
}
