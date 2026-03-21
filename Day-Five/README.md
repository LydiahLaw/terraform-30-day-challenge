# Day 05 - Scaling Infrastructure and Understanding Terraform State

## What am I here to do today?

Day 5 has two threads running in parallel. The infrastructure side is an
extension of Day 4  the same ALB and ASG cluster redeployed with updated
naming. The real focus today is Terraform state: what it is, what it
contains, what happens when it gets out of sync with real infrastructure,
and why managing it correctly matters more than most beginners realize.

---

## Tasks Completed

1. Finished Chapter 2 and started Chapter 3 of *Terraform: Up & Running*
   focusing on state, remote backends, and state locking
2. Completed Lab: Benefits of State
3. Deployed scaled infrastructure with ALB and ASG in Day-Five folder
4. Opened and read through terraform.tfstate after deployment
5. Ran experiment 1: manual state file tampering
6. Ran experiment 2: console drift detection on the ALB
7. Destroyed all resources after experiments
8. Published blog post
9. Shared on social media

---

## Files

- `main.tf` — provider, data sources, security groups, launch template,
  ASG, ALB, target group, listener, and outputs
- `variables.tf` — input variables for region, instance type, server port,
  and server name

---

## Infrastructure Code
```hcl
provider "aws" {
  region = var.region
}

data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb_sg" {
  name = "terraform-day05-alb-sg"

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

resource "aws_lb" "web" {
  name               = "terraform-day05-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "web" {
  name     = "terraform-day05-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "terraform-day05-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 5

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "The domain name of the load balancer"
}
```

---

## Deployment Output
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = "terraform-day05-alb-XXXXXXXXX.eu-central-1.elb.amazonaws.com"
```

---

## State File Experiments

### Experiment 1: Manual State Tampering

Edited the `name_prefix` value for the launch template inside
`terraform.tfstate` from `terraform-day05-` to `terraform-day05-modified-`
and ran `terraform plan`.

Result: no changes detected.

What this teaches: Terraform does not rely solely on the local state file
when running plan. It calls the AWS API to check what actually exists,
refreshes state with real values, and then compares against the
configuration. Editing the local file manually does not fool it because it
goes straight to the source.

### Experiment 2: Console Drift Detection

Added a tag directly to the ALB in the AWS console:
- Key: `Environment`
- Value: `manual`

Then ran `terraform plan` without changing any code.

Result:
```
~ resource "aws_lb" "web" {
    ~ tags = {
        - "Environment" = "manual" -> null
      }
  }

Plan: 0 to add, 1 to change, 0 to destroy.
```
<img width="1366" height="768" alt="alb tag chnages" src="https://github.com/user-attachments/assets/5e99034c-06b0-4a51-a676-d5ea7428d43c" />


What this teaches: Terraform detected that the ALB in AWS had a tag that
does not exist in the configuration and proposed removing it. The tilde
means an in-place update. The minus sign means that tag will be deleted to
bring real infrastructure back in line with the code.

Note: adding tags directly to EC2 instances launched by the ASG did not
show as drift because those instances are not directly managed by Terraform.
The ASG manages them. Only resources defined explicitly in the configuration
are tracked in state.

---

## Block Comparison Table

| Block | Purpose | When to Use | Example |
|---|---|---|---|
| provider | Configures the cloud provider and region | Once per provider | `provider "aws" { region = "eu-central-1" }` |
| resource | Defines infrastructure to create or manage | Every piece of infrastructure | `resource "aws_instance" "web" { ... }` |
| variable | Declares an input variable | To avoid hardcoding values | `variable "instance_type" { default = "t2.micro" }` |
| output | Exposes values after apply | To surface IPs, DNS names, IDs | `output "alb_dns" { value = aws_lb.web.dns_name }` |
| data | Reads existing resources | To reference things not managed by this config | `data "aws_vpc" "default" { default = true }` |

---

## What I Learned

### What the State File Contains

The state file is a JSON snapshot of every resource Terraform has created.
It stores resource IDs, attributes, metadata, and dependencies. It is
Terraform's memory. Without it, Terraform has no way of knowing what
already exists in AWS and would try to create everything from scratch on
every apply.

### Why State Should Never Be Committed to Git

The state file contains sensitive information including resource IDs, IP
addresses, and potentially secrets. Committing it to a public repository
exposes all of that. In a team it also creates conflicts — two people
running Terraform against the same local state file will overwrite each
other's changes.

### Remote State and State Locking

The solution is storing state remotely in an S3 bucket. Every team member
runs Terraform against the same state file stored in one place. State
locking via DynamoDB prevents two people from running apply at the same
time, which would corrupt the state file.
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "day05/terraform.tfstate"
    region = "eu-central-1"
  }
}
```

---

## Challenges and Fixes

The ASG instances did not show drift when tags were added to them directly
in the console. This is because ASG-managed instances are not tracked
individually in Terraform state. Switching to the ALB, which is a directly
managed resource, showed the expected drift detection behavior immediately.

---

## Blog Post

https://medium.com/@LydLaw/managing-high-traffic-applications-with-aws-elastic-load-balancer-and-terraform-efa5423fa1a7
---

## Social Media

https://www.linkedin.com/posts/lydiah-nganga_managing-high-traffic-applications-with-aws-activity-7441131062212190208-b7Tl?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAcf9WQBEuwTg-q28iqt79pwr6J3YWONKAI
