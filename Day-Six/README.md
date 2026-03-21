# Day 06 - Understanding and Managing Terraform State

## What am I here to do today?

Day 6 goes deep on Terraform state. The goal is to understand what the
state file actually contains, why local state breaks down in a team
environment, and how to configure remote state storage correctly using
S3 and DynamoDB. This is one of the most certification-tested topics in
the challenge and one of the most important habits to build early as an
infrastructure engineer.

---

## Tasks Completed

1. Read Chapter 3 of *Terraform: Up & Running* — pages 145 through 157,
   focusing on what state is, shared storage, and managing state across teams
2. Completed Lab 1: Output Values
3. Completed Lab 2: State Management
4. Deployed S3 bucket, DynamoDB table, and security group
5. Ran `terraform state list` and `terraform state show` to inspect state
6. Configured remote S3 backend and migrated local state
7. Confirmed state file appeared in S3 console
8. Tested state locking with two terminal windows
9. Published blog post
10. Shared on social media

---

## Files

- `main.tf` — S3 bucket, versioning, encryption, DynamoDB table,
  security group, backend configuration, and outputs

---


## Infrastructure Code
```hcl
terraform {
  backend "s3" {
    bucket         = "lydiah-terraform-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "lydiah-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_security_group" "example" {
  name        = "terraform-day06-sg"
  description = "Day 06 state inspection example"

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

output "security_group_id" {
  value       = aws_security_group.example.id
  description = "ID of the example security group"
}
```
<img width="1366" height="631" alt="s3 bucket created" src="https://github.com/user-attachments/assets/722ce57b-b839-4f67-82db-3c93cb92505e" />
<img width="1366" height="619" alt="dynamodb created " src="https://github.com/user-attachments/assets/b7378a4c-92db-41d9-82da-09865e1e7643" />
<img width="1366" height="619" alt="tfstae" src="https://github.com/user-attachments/assets/4ad74fb1-8862-4ff9-8acd-985bf5cd2cc4" />



---

## State Inspection

### terraform state list
```
aws_dynamodb_table.terraform_locks
aws_s3_bucket.terraform_state
aws_s3_bucket_server_side_encryption_configuration.default
aws_s3_bucket_versioning.enabled
aws_security_group.example
```
<img width="1366" height="768" alt="terraform state" src="https://github.com/user-attachments/assets/cf90f88d-ffd5-41a9-a2c3-bf379d5faf16" />

### terraform state show aws_security_group.example
```
resource "aws_security_group" "example" {
    arn         = "arn:aws:ec2:eu-central-1:835960997504:security-group/sg-060aad0089d78268b"
    description = "Day 06 state inspection example"
    id          = "sg-060aad0089d78268b"
    name        = "terraform-day06-sg"
    egress      = [
      {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 0
        protocol    = "-1"
        to_port     = 0
      }
    ]
    ingress     = [
      {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 80
        protocol    = "tcp"
        to_port     = 80
      }
    ]
}
```

---

## Migration Output
```
$ terraform init
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local"
  backend to the newly configured "s3" backend. No existing state was
  found in the newly configured "s3" backend. Do you want to copy this
  state to the new "s3" backend? Enter "yes" to copy and "no" to start
  with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

State file confirmed in S3 at:
`lydiah-terraform-state-bucket/global/s3/terraform.tfstate`
Size: 9.4 KB, last modified March 21, 2026.

---
<img width="1366" height="768" alt="migrate " src="https://github.com/user-attachments/assets/702634d7-ed1d-4338-a0c8-62899be367c4" />

## State Locking Test

Ran `terraform apply` in terminal 1 and immediately ran `terraform plan`
in terminal 2. Terminal 2 returned:
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional
request failed
Lock Info:
  ID:        16bba9e8-f2a8-d2d8-a596-d4969d89a765
  Path:      lydiah-terraform-state-bucket/global/s3/terraform.tfstate
  Operation: OperationTypeApply
  Who:       DESKTOP-0SGKOJG\USER@DESKTOP-0SGKOJG
  Version:   1.14.7
  Created:   2026-03-21 18:42:43 +0000 UTC
```

DynamoDB blocked the second terminal from acquiring the lock while the
first apply was running. This prevents concurrent writes to the state
file which would corrupt it.
<img width="1366" height="768" alt="state lock" src="https://github.com/user-attachments/assets/09346109-9748-4877-b170-bb137f8a32d6" />


---

## What I Learned

### Why State Should Never Be Committed to Git

The state file contains sensitive data including resource IDs, IP
addresses, and sometimes secrets depending on what is being deployed.
Committing it to a public repository exposes all of that. Git history
is also permanent — a secret committed once stays in the history even
after the file is deleted. Beyond security, Git is not designed for
concurrent file access. Two people committing different versions of the
state file will create conflicts that corrupt it.

### The Bootstrap Problem

You cannot use Terraform to create the S3 bucket and DynamoDB table
that Terraform needs as its backend. The solution is to create those
resources first using local state, then add the backend block and run
`terraform init` again to migrate. Terraform detects the new backend
and offers to copy the existing local state to S3.

### State Locking

State locking prevents two engineers from running `terraform apply` at
the same time against the same state file. Without it, concurrent
applies can write conflicting updates and corrupt the state. DynamoDB
acts as a distributed lock. Terraform writes a lock entry before making
any changes and releases it when done. Anyone else trying to run a
command while the lock is held gets an error.

### S3 Versioning

Versioning on the S3 bucket preserves every previous version of the
state file. If a bad apply corrupts the state, you can roll back to an
earlier version from the S3 console without losing everything.

---

## Challenges and Fixes

No errors during the deployment. The one thing worth noting is the
bootstrap order. The S3 bucket and DynamoDB table must exist before you
add the backend block to main.tf. Adding the backend block before the
resources exist will cause `terraform init` to fail because Terraform
tries to connect to a bucket that is not there yet.

---

## Blog Post

[Managing Terraform State: Best Practices and Secure Remote Storage](paste your Medium URL here)

---

## Social Media

[[LinkedIn Post](paste your LinkedIn URL here)](https://www.linkedin.com/posts/lydiah-nganga_managing-terraform-state-best-practices-activity-7441219205196300288-q16y?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAcf9WQBEuwTg-q28iqt79pwr6J3YWONKAI)

