# Day 07 - State Isolation: Workspaces vs File Layouts

## What am I here to do today?

Day 7 is about managing infrastructure across multiple environments without
them interfering with each other. Two approaches are covered: Terraform
Workspaces, which create isolated state files from a single configuration
directory, and File Layout isolation, which uses separate directories per
environment each with its own backend configuration. The goal is to
understand the tradeoffs between both and know when to use each one.

---

## Tasks Completed

1. Read Chapter 3 of *Terraform: Up & Running* — pages 160 through 193,
   focusing on state isolation, workspaces, file layouts, and the remote
   state data source
2. Completed Lab 1: State Management
3. Completed Lab 2: State Locking
4. Created dev, staging, and production workspaces
5. Deployed to dev and staging workspaces and confirmed separate state
   files in S3
6. Built file layout directory structure with separate backend configs
7. Deployed dev and production independently from separate directories
8. Configured terraform_remote_state data source in staging to read
   dev outputs
9. Destroyed all compute resources after confirmation
10. Published blog post
11. Shared on social media

---

## Project Structure
```
Day-Seven/
├── main.tf                  # Workspace-aware configuration
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── backend.tf
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── backend.tf
```

---

## Part 1: Workspaces

### Workspace Configuration
```hcl
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
  ami           = "ami-0e872aee57663ae2d"
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
```
<img width="1366" height="768" alt="dev main" src="https://github.com/user-attachments/assets/59e63d64-07b1-4194-a50a-06b181249f54" />


### Workspace Commands
```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new production

# List all workspaces
terraform workspace list

# Switch between workspaces
terraform workspace select dev

# Check active workspace
terraform workspace show
```
<img width="1366" height="768" alt="workspaces created " src="https://github.com/user-attachments/assets/30f541eb-2466-4ed8-a35e-2962810ef367" />

### Workspace List Output
```
  default
* dev
  staging
  production
```

### S3 State File Paths per Workspace
```
env:/dev/day-seven/workspaces/terraform.tfstate
env:/staging/day-seven/workspaces/terraform.tfstate
env:/production/day-seven/workspaces/terraform.tfstate
```

---
<img width="1366" height="631" alt="workspaces created" src="https://github.com/user-attachments/assets/4138657c-f105-4fba-86ff-40c9fbdf49e8" />

## Part 2: File Layout Isolation

### dev/backend.tf
```hcl
terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### production/backend.tf
```hcl
terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "environments/production/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

The key path is the only difference between the two. Each environment
writes its state to a completely separate location in S3. A terraform
apply in dev cannot read or modify the production state file.

---
<img width="1366" height="614" alt="separate environments" src="https://github.com/user-attachments/assets/fb126e06-30b2-47bd-aef8-788b45f73133" />


## Part 3: Remote State Data Source

The staging configuration reads outputs from the dev state file without
managing any of those resources itself:
```hcl
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
```

---

## Workspaces vs File Layouts

| | Workspaces | File Layouts |
|---|---|---|
| State isolation | Yes | Yes |
| Code isolation | No | Yes |
| Risk of wrong environment | High | Low |
| Backend config per environment | No | Yes |
| Recommended for production | No | Yes |
| Setup overhead | Low | Higher |

### When to use workspaces
- Solo projects or quick testing
- Environments that are nearly identical
- Low risk of cross-environment mistakes

### When to use file layouts
- Team environments
- Production infrastructure
- When dev and production need meaningfully different configurations

---

## State Locking Across Workspaces

Each workspace acquires its own lock in DynamoDB when running a command.
Two workspaces do not lock each other because the lock key is tied to the
specific state file path, not the bucket. Running apply in dev and apply
in staging simultaneously is safe — they write to different state files
and acquire different locks.

---

## What I Learned

The core difference between workspaces and file layouts is not just about
state files. Workspaces isolate state but share code. File layouts isolate
everything — state, code, and backend configuration. That distinction is
what makes file layouts safer for production. 
With workspaces, a bug in your configuration exists in all environments simultaneously. With file
layouts, you control exactly what goes into each environment and when.

The remote state data source solves the problem of sharing data between
isolated configurations without coupling them directly. One configuration
exposes outputs, another reads them. They stay independent but can still
pass information between each other.

---

## Challenges and Fixes

Switching between workspaces requires checking the active workspace before
every apply. Running terraform workspace show before terraform apply
is a habit worth building early. Forgetting to check is exactly the kind
of mistake that leads to applying dev configuration to production.

For the file layout setup, each environment directory requires its own
terraform init before the first apply. Running init from the wrong
directory will fail because the backend configuration is environment-specific.

---

## Blog Post

[State Isolation: Workspaces vs File Layouts — When to Use Each](https://medium.com/@LydLaw/state-isolation-workspaces-vs-file-layouts-when-to-use-each-01e44015eda0)

---

## Social Media

[LinkedIn Post](https://www.linkedin.com/posts/lydiah-nganga_30dayterraformchallenge-terraformchallenge-share-7442232754861142016-mf0M?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAcf9WQBEuwTg-q28iqt79pwr6J3YWONKAI)
