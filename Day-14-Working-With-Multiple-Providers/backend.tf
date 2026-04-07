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
    key            = "day14/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# Default provider — primary region
provider "aws" {
  region = "eu-central-1"
}

# Aliased provider — secondary region
provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}

# Multi-account provider — production (assume_role)
provider "aws" {
  alias  = "production"
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformDeployRole"
  }
}

# Multi-account provider — staging (assume_role)
provider "aws" {
  alias  = "staging"
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/TerraformDeployRole"
  }
}
