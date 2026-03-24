# Day 08 - Building Reusable Infrastructure with Terraform Modules

## Introduction

Day 8 is about stopping repetition at scale. By this point in the challenge
the same web server cluster had been written three times across three days
with slightly different names each time. Modules are how you package that
infrastructure logic once and call it from anywhere — different environments,
different teams, different projects — without duplicating code.

---

## Tasks Completed

- Read Chapter 4 of Terraform: Up & Running — pages 115 through 139, focusing
  on module basics, module inputs, and module outputs
- Completed Lab 1: Terraform Workspaces
- Completed Lab 2: Terraform Modules
- Built a reusable webserver-cluster module with variables, outputs, and README
- Created dev and production calling configurations
- Deployed from the dev calling configuration and confirmed the cluster was reachable
- Destroyed dev deployment after confirmation
- Ran terraform init on production to confirm same module resolves without modification
- Refactored Days 3-5 flat code into the module structure
- Published blog post
- Shared on social media

---

## Project Structure
```
Day-Eight/
├── modules/
│   └── services/
│       └── webserver-cluster/
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── README.md
└── live/
    ├── dev/
    │   └── services/
    │       └── webserver-cluster/
    │           └── main.tf
    └── production/
        └── services/
            └── webserver-cluster/
                └── main.tf
```

---

## Module Inputs
```hcl
variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the cluster"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}

variable "server_port" {
  description = "Port the server uses for HTTP"
  type        = number
  default     = 8080
}
```

`cluster_name`, `min_size`, and `max_size` are required — no defaults. Every
resource name inside the module is prefixed with `var.cluster_name` so the
same module can run in multiple environments without naming conflicts.

---

## Module Outputs
```hcl
output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "The name of the Auto Scaling Group"
}
```

---

## Calling Configurations

Dev environment — t2.micro, 2 to 4 instances:
```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
  server_port   = 80
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
```

Production environment — t2.medium, 4 to 10 instances:
```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-production"
  instance_type = "t2.medium"
  min_size      = 4
  max_size      = 10
  server_port   = 80
}
```

Same module, different inputs. No code duplication.

---

## Deployment Confirmation

Deployed from `live/dev/services/webserver-cluster`. The cluster came up with
two instances behind the ALB. After the initial 502, the fix was passing
`server_port = 80` explicitly since Apache serves on port 80 by default, not
the 8080 default in the module. Screenshot of the running cluster is in the
project assets.

---
<img width="1366" height="768" alt="output apply" src="https://github.com/user-attachments/assets/5b8f54b2-d907-4ca2-bcf6-399deb3ac34b" />
<img width="1366" height="768" alt="browser" src="https://github.com/user-attachments/assets/435ec061-1172-447e-8d93-fabafb65a53c" />


## Module Design Decisions

- `cluster_name`, `min_size`, and `max_size` are required inputs because they
  will always differ between environments
- `instance_type` defaults to t2.micro — sensible for dev, overridden for
  production
- `server_port` defaults to 8080 to match the book examples but should be
  set to 80 explicitly when using Apache
- The AMI is kept hardcoded inside the module — it is region-specific and
  consistent across environments, so exposing it as a variable adds noise
  without real benefit
- Both `alb_dns_name` and `asg_name` are exposed as outputs — the DNS name
  for browser verification, the ASG name for monitoring and debugging

---

## Refactoring Observations

Days 4 and 5 were almost identical files same security groups, same ASG
and ALB structure, just with day04 and day05 baked into every resource name.
Refactoring meant replacing every hardcoded name with `${var.cluster_name}`,
moving sizing and instance type to variables, and removing one full copy of
the code. What was 80 lines per environment became a single module and an
8-line calling configuration per environment.


---

## Chapter 4 Learnings

- A root module is the configuration you run Terraform commands from directly.
  A child module is any module called via a module block from another
  configuration. Every Terraform configuration is technically a module.
- When you add a new module source, terraform init downloads and caches it
  into .terraform/modules/. Without running init first, Terraform does not
  know the module exists and will error on plan.
- Module outputs are stored in the state file under the module's namespace.
  They are accessible to the calling configuration as
  module.module_name.output_name and are visible in terraform state show.

---

## Challenges and Fixes

The cluster deployed but returned a 502 Bad Gateway. The ALB was up but
instances were failing health checks. The cause was the instance security
group allowing traffic only on `var.server_port` (defaulting to 8080) while
Apache was serving on port 80. The fix was passing `server_port = 80`
explicitly in the dev calling configuration. Health checks started passing
within two minutes and the ALB began forwarding traffic correctly.

---

## Blog Post
[Building Reusable Infrastructure with Terraform Modules](https://medium.com/@LydLaw/building-reusable-infrastructure-with-terraform-modules-1b7834f88e48)

## Social Media
[LinkedIn Post](https://www.linkedin.com/posts/lydiah-nganga_30dayterraformchallenge-terraformchallenge-share-7442327423175770113-_x4P?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAcf9WQBEuwTg-q28iqt79pwr6J3YWONKAI)
