terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "day-seven/workspaces/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type per environment"
  type        = map(string)
  default = {
    dev        = "t2.micro"
    staging    = "t2.micro"
    production = "t2.micro"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0cebfb1f908092578"
  instance_type = var.instance_type[terraform.workspace]

  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "environment" {
  value = terraform.workspace
}
