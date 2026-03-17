# Day 03 - Deploying Your First Server with Terraform

## What am I here to do today?

Today is where Terraform goes from theory to practice. The goal was to write
real Terraform code, deploy a working web server on AWS, confirm it serves
an HTML page over HTTP, and tear it down cleanly. Two core building blocks
were introduced today: the provider block and the resource block.

---

## Tasks Completed

1. Read Chapter 2 of *Terraform: Up & Running* — sections on Deploying a
   Single Server and Deploying a Web Server
2. Completed Lab 1: Intro to the Terraform Provider Block
3. Completed Lab 2: Intro to the Terraform Resource Block
4. Deployed a web server on AWS using Terraform
5. Confirmed the server was reachable in the browser
6. Destroyed all resources after confirmation
7. Created architecture diagram
8. Published blog post
9. Shared on social media

---

## Terraform Code
```hcl
provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg"
  description = "Allow HTTP traffic on port 80"

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

resource "aws_instance" "web_server" {
  ami                         = "ami-0e872aee57663ae2d"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello from Terraform - Day 03</h1>" > /var/www/html/index.html
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-day03-server"
  }
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "The public IP of the web server"
}
```

---

## Deployment Output
```
aws_security_group.web_sg: Creating...
aws_security_group.web_sg: Creation complete after 4s [id=sg-0e1842135f9e6fe79]
aws_instance.web_server: Creating...
aws_instance.web_server: Creation complete after 38s [id=i-083e47e05c0c9fc5c]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

public_ip = "3.71.16.141"
```

---

## Server Confirmation

Opened `http://3.71.16.141` in the browser and confirmed the page loaded
with the text: **Hello from Terraform - Day 03**

Screenshot saved in the `screenshots` folder.

---

## Destroy Output
```
aws_instance.web_server: Destroying... [id=i-083e47e05c0c9fc5c]
aws_instance.web_server: Still destroying... [00m10s elapsed]
aws_instance.web_server: Still destroying... [00m20s elapsed]
aws_instance.web_server: Still destroying... [00m30s elapsed]
aws_instance.web_server: Destruction complete after 31s
aws_security_group.web_sg: Destroying... [id=sg-0e1842135f9e6fe79]
aws_security_group.web_sg: Destruction complete after 1s

Destroy complete! Resources: 2 destroyed.
```

---

## Architecture Diagram

![Architecture Diagram](screenshots/architecture-diagram.png)

The diagram shows:
- Cloud provider: AWS, region eu-central-1 (Frankfurt)
- One EC2 instance (t2.micro) running Apache, instance ID i-083e47e05c0c9fc5c
- Security group sg-0e1842135f9e6fe79 allowing inbound HTTP on port 80
  and all outbound traffic
- Public internet access via the default VPC internet gateway
- Public IP: 3.71.16.141 (destroyed after confirmation)

---

## Key Commands Used
```bash
# Initialise the working directory and download the AWS provider
terraform init

# Preview what Terraform will create before touching AWS
terraform plan

# Deploy the infrastructure
terraform apply

# Tear down all resources after confirmation
terraform destroy
```

---

## What I Learned

**Provider block vs resource block**

The provider block tells Terraform which cloud platform to target and how
to connect to it. Without it Terraform has no destination for its API
calls. The resource block describes a specific piece of infrastructure you
want to exist. Terraform reads all resource blocks, works out the
dependencies between them, and creates them in the right order. The
security group was created before the EC2 instance because the instance
block references the security group ID directly.

**What terraform plan actually does**

Plan does not touch AWS. It reads your configuration, compares it against
the current state file, and produces a diff of what will change. A plus
sign means the resource will be created, a minus sign means it will be
deleted, and a tilde means it will be updated in place. Today the plan
showed 2 to add, 0 to change, 0 to destroy, which matched exactly what
was deployed.

---

## Challenges and Fixes

The AMI ID in the book targets us-east-2 and does not work in
eu-central-1. Used the AWS CLI to fetch the correct Ubuntu 20.04 AMI ID
for Frankfurt before writing the configuration:
```bash
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
  "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text \
  --region eu-central-1
```

---

## Social Media

URL: [paste your LinkedIn or X post URL here]
