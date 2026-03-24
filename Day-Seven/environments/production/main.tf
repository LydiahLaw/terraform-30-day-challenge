provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg-${var.environment}"
  description = "Security group for ${var.environment}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0cebfb1f908092578"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name        = "web-${var.environment}"
    Environment = var.environment
  }
}