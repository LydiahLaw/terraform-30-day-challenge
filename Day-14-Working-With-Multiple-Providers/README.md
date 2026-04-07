# Day 14: Working with Multiple Providers

## Overview

This project covers how Terraform's provider system works — how providers are installed, versioned, and configured — and applies that knowledge by deploying resources across multiple AWS regions using provider aliases. The practical demonstration is an S3 cross-region replication setup: a primary bucket in eu-central-1 and a replica in eu-west-1, with replication configured between them.



## What this configuration does

- Defines a default provider for eu-central-1 and an aliased provider for eu-west-1
- Deploys a primary S3 bucket in eu-central-1 using the default provider
- Deploys a replica S3 bucket in eu-west-1 using the aliased provider
- Enables versioning on both buckets (required for replication)
- Configures S3 cross-region replication from primary to replica
- Creates an IAM role and policy scoped to replication permissions only
- Includes multi-account provider configuration using `assume_role` for reference



## Project structure

```
Day-14-Working-With-Multiple-Providers/
├── backend.tf       # Provider configurations — default, aliased, and multi-account
├── main.tf          # S3 buckets, versioning, and replication configuration
├── iam.tf           # IAM role and policy for S3 replication
├── variables.tf     # Bucket name variables
├── outputs.tf       # Bucket ARNs, names, and replication role ARN
└── README.md
```



## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0
- S3 bucket for remote state: `lydiah-terraform-state-bucket`
- DynamoDB table for state locking: `terraform-state-locks`



## Provider configuration

### Default and aliased providers

```hcl
# Default provider — primary region
provider "aws" {
  region = "eu-central-1"
}

# Aliased provider — secondary region
provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}
```

Resources that do not specify a `provider` argument use the default provider. Resources that need to deploy to eu-west-1 reference the alias explicitly:

```hcl
resource "aws_s3_bucket" "replica" {
  provider = aws.eu_west
  bucket   = var.replica_bucket_name
}
```

### Multi-account providers using assume_role

```hcl
provider "aws" {
  alias  = "production"
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformDeployRole"
  }
}

provider "aws" {
  alias  = "staging"
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/TerraformDeployRole"
  }
}
```

Terraform calls AWS STS to exchange your current credentials for temporary credentials scoped to the target role. All API calls for resources referencing that provider run under the role's permissions. This configuration is included for reference — no resources reference these providers in this project as it requires two separate AWS accounts.



## Provider versioning

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
```

The `~> 5.0` constraint allows any version >= 5.0 and < 6.0. This receives patch and minor updates automatically while protecting against breaking changes from a major version bump.

---

## The .terraform.lock.hcl file

After `terraform init`, Terraform creates a lock file recording the exact provider version selected:

```
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.100.0"
  constraints = "~> 5.0"
  hashes = [...]
}
```

- `version` — the exact version installed. Every team member and CI system uses this version when they run `terraform init`
- `constraints` — the version constraint from `required_providers`, recorded for reference
- `hashes` — cryptographic checksums of the provider binary across platforms, used to verify the downloaded binary has not been tampered with

This file must be committed to version control.



## Setup and usage

### Step 1 — set AWS credentials as environment variables

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-central-1"
```

### Step 2 — initialise Terraform

```bash
terraform init
```

### Step 3 — review the plan

```bash
terraform plan
```

Expected output:

```
Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + primary_bucket_arn   = (known after apply)
  + primary_bucket_name  = (known after apply)
  + replica_bucket_arn   = (known after apply)
  + replica_bucket_name  = (known after apply)
  + replication_role_arn = (known after apply)
```

### Step 4 — apply

```bash
terraform apply -auto-approve
```
<img width="1366" height="768" alt="Screenshot (1811)" src="https://github.com/user-attachments/assets/0b2d9a38-577e-48f5-9985-fc776235abf5" />

<img width="1366" height="631" alt="Screenshot (1812)" src="https://github.com/user-attachments/assets/96075944-7ba0-4f7e-a5ad-0fc6e12a28b0" />


### Step 5 — destroy when done

```bash
terraform destroy -auto-approve
```

---

## Resources created

| Resource | Type | Region |
|---|---|---|
| lydiah-primary-bucket-day14 | S3 bucket | eu-central-1 |
| lydiah-replica-bucket-day14 | S3 bucket | eu-west-1 |
| aws_s3_bucket_versioning.primary | S3 versioning | eu-central-1 |
| aws_s3_bucket_versioning.replica | S3 versioning | eu-west-1 |
| aws_s3_bucket_replication_configuration | S3 replication | eu-central-1 |
| s3-replication-role-day14 | IAM role | global |
| s3-replication-policy-day14 | IAM role policy | global |

---

## Key concepts

### Why depends_on is needed on the replication configuration

Terraform cannot automatically infer that versioning must be enabled before replication can be configured. Without `depends_on`, Terraform might attempt to create the replication configuration before versioning is in place, which would fail. The explicit dependency tells Terraform the correct order.

```hcl
resource "aws_s3_bucket_replication_configuration" "replication" {
  ...
  depends_on = [aws_s3_bucket_versioning.primary]
}
```

### What happens when state is lost

During this project the remote state bucket was accidentally deleted from the console. Terraform could not read or write state, and `terraform destroy` reported nothing to destroy — because from Terraform's perspective, nothing existed. The resources were still live in AWS and had to be cleaned up manually via CLI. This is a practical demonstration of why the state bucket must be treated with the same care as the infrastructure it tracks.

---

## Resources

- [Terraform: Up & Running — Chapter 7: Working with Multiple Providers](https://www.terraformupandrunning.com/)
- [Terraform AWS Provider Registry](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Day 14 blog post](https://medium.com/@LydLaw/getting-started-with-multiple-providers-in-terraform-d6b7120d254c)

---

## Conclusion

This configuration demonstrates provider aliases as the mechanism for multi-region deployments in Terraform. The default provider handles eu-central-1. The aliased provider handles eu-west-1. Resources explicitly reference the alias when they need to deploy outside the default region. The S3 replication setup makes this concrete — two buckets, two regions, one configuration, one `terraform apply`. The multi-account `assume_role` pattern extends the same idea across AWS account boundaries.
