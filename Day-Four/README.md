# Day 04 - Mastering Basic Infrastructure with Terraform

## What am I here to do today?

Day 4 builds on the single server from yesterday. The focus is on two things:
making infrastructure configurable using input variables, and scaling it into
a cluster that can handle real traffic. By the end of the day the deployment
goes from one hardcoded server to a load-balanced, auto-scaling setup running
across multiple availability zones in Frankfurt.

---

## Tasks Completed

1. Read Chapter 2 of *Terraform: Up & Running* — pages 60 through 69, focusing
   on input variables, the DRY principle, and clustered architecture
2. Completed Lab 1: Intro to the Terraform Data Block
3. Completed Lab 2: Intro to Input Variables
4. Deployed a configurable web server using input variables
5. Deployed a clustered web server with an ASG and ALB
6. Confirmed both deployments in the browser
7. Destroyed all resources after confirmation
8. Published blog post
9. Shared on social media

---

## Files

- `main.tf` — provider, security groups, launch template, ASG, ALB,
  target group, listener, and outputs
- `variables.tf` — input variables for region, instance type, server port,
  and server name

---

## Configurable Web Server

### variables.tf
```hcl
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "server_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-day04-server"
}
```

### Deployment Output
```
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

public_ip = "52.59.216.93"
```

Server confirmed at `http://52.59.216.93` — page returned:
**Hello from Terraform - Day 04 Configurable Server Enjoying The Journey**

---

<img width="1366" height="768" alt="Screenshot (1620)" src="https://github.com/user-attachments/assets/b07a1342-2703-4b54-9cb6-31ea7de369be" />


## Clustered Web Server

### Architecture
```
Internet
    |
Application Load Balancer (port 80)
    |
Target Group
    |
Auto Scaling Group (min: 2, max: 5)
    |
EC2 Instances across eu-central-1 availability zones
```

### Key Commands Used
```bash
# Initialise and download providers
terraform init

# Preview changes before applying
terraform plan

# Deploy the infrastructure
terraform apply

# Tear down all resources
terraform destroy
```

### Deployment Output
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = "terraform-day04-alb-846501425.eu-central-1.elb.amazonaws.com"
```
<img width="1366" height="768" alt="Screenshot (1623)" src="https://github.com/user-attachments/assets/9ca52d08-5b88-4101-be72-beeccc195fb9" />


Server confirmed at
`http://terraform-day04-alb-846501425.eu-central-1.elb.amazonaws.com`
— page returned: **Hello from Terraform - Day 04 Cluster**

---


## What I Learned

### DRY Principle

DRY means every value has one source of truth. Before variables, instance
type and region were written directly into main.tf. In a team, two people
working in different environments embed different values in the same files
and someone's change breaks someone else's deployment. With variables, the
logic in main.tf never changes. Only the values in variables.tf do. Change
one default and every resource referencing it updates automatically.

### Data Sources

Terraform is not only for creating resources. Data sources read things that
already exist in your AWS account and make their attributes available in
your configuration. The default VPC and its subnets already existed. Fetching
them with data sources meant the configuration works across accounts and
regions without hardcoding IDs that change between environments.

### Configurable vs Clustered

The configurable server is still one EC2 instance. Better structured code,
same underlying infrastructure. If that instance fails, the service goes
down. The cluster runs a minimum of two instances across multiple
availability zones. The ASG replaces unhealthy instances automatically and
scales up when traffic increases. The ALB means no single instance is a
point of failure.

---

## Challenges and Fixes

The ALB took just over 2 minutes to provision, which is normal behavior for
ALBs in AWS. Terraform handled the dependency order automatically and waited
for the ALB to finish before creating the listener. The user data in the
launch template requires base64 encoding, unlike the `aws_instance` resource
which handles that automatically.

---

## Blog Post

https://lydiah.hashnode.dev/deploying-a-highly-available-web-app-on-aws-using-terraform
---

## Social Media

https://www.linkedin.com/posts/lydiah-nganga_deploying-a-highly-available-web-app-on-aws-activity-7440131949836316672-Wtv_?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAcf9WQBEuwTg-q28iqt79pwr6J3YWONKAI
