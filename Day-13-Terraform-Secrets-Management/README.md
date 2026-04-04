# Day 13: Terraform Secrets Management

## Overview

This project covers secrets management in Terraform — specifically how secrets leak and how to stop every leak path using AWS Secrets Manager and Terraform's built-in sensitive value handling. The configuration provisions an RDS MySQL instance using credentials fetched at runtime from AWS Secrets Manager, with no secret values written to any configuration file.



## The problem

Terraform configurations handle secrets in three places, and each one is a potential leak path:

- Hardcoded values in `.tf` files end up in Git history permanently
- Variable default values are stored in configuration files and committed to source control
- Even when the first two are handled correctly, Terraform writes the resolved values of sensitive resource attributes into `terraform.tfstate` in plaintext

Closing one or two of these paths is not enough. All three need to be addressed.



## What this configuration does

- Creates a secret in AWS Secrets Manager via CLI (outside of Terraform, to avoid state exposure)
- Fetches the secret at apply time using `aws_secretsmanager_secret` and `aws_secretsmanager_secret_version` data sources
- Decodes the JSON secret string into a usable map using `jsondecode`
- Passes the credentials to an RDS MySQL instance without writing them to any `.tf` file
- Marks all sensitive outputs with `sensitive = true` to prevent values from appearing in terminal output and logs
- Uses an encrypted S3 backend with DynamoDB locking for state management



## Project structure

```
Day-13-Terraform-Secrets-Management/
├── backend.tf       # S3 backend with encryption and DynamoDB locking
├── main.tf          # Secrets Manager data sources, locals, RDS resource
├── variables.tf     # Non-sensitive variables only — no secret defaults
├── outputs.tf       # Sensitive outputs marked with sensitive = true
├── .gitignore       # Excludes state files, .terraform directory, tfvars
└── README.md
```



## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0
- S3 bucket for remote state: `lydiah-terraform-state-bucket`
- DynamoDB table for state locking: `terraform-state-locks`



## Setup

### Step 1 — set AWS credentials as environment variables

Never put credentials in your Terraform configuration. The AWS provider reads these automatically:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-central-1"
```

### Step 2 — create the secret in AWS Secrets Manager via CLI

Bootstrap secrets are always created outside of Terraform. If Terraform creates the secret, the value ends up in state — you gain nothing.

```bash
aws secretsmanager create-secret \
  --name "prod/db/credentials" \
  --secret-string '{"username":"dbadmin","password":"your-secure-password-here"}' \
  --region eu-central-1
```

Expected response:

```json
{
    "ARN": "arn:aws:secretsmanager:eu-central-1:...:secret:prod/db/credentials-xxxxx",
    "Name": "prod/db/credentials",
    "VersionId": "..."
}
```

### Step 3 — initialise Terraform

```bash
terraform init
```

### Step 4 — run the plan

```bash
terraform plan
```

Expected output confirms credentials are fetched from Secrets Manager and sensitive outputs are masked:

```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + db_endpoint = (sensitive value)
  + db_username = (sensitive value)
```



## Key concepts

### Fetching secrets at runtime

Instead of writing credentials into `.tf` files, use data sources to fetch them at apply time:

```hcl
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}
```

The `jsondecode` function converts the JSON string stored in Secrets Manager into a Terraform map. Individual values are then referenced as `local.db_credentials["username"]` and `local.db_credentials["password"]`.

### sensitive = true

Marking outputs and variables as sensitive prevents their values from appearing in plan and apply output:

```hcl
output "db_endpoint" {
  value     = aws_db_instance.example.endpoint
  sensitive = true
}
```

This does not prevent the values from being stored in state. It protects terminal output and CI/CD logs.

### State file security

Secrets appear in `terraform.tfstate` in plaintext regardless of how they are managed in configuration. The state file must be secured:

```hcl
backend "s3" {
  bucket         = "lydiah-terraform-state-bucket"
  key            = "day13/terraform.tfstate"
  region         = "eu-central-1"
  dynamodb_table = "terraform-state-locks"
  encrypt        = true
}
```

S3 bucket verification:

```bash
# Block public access — all four settings should be true
aws s3api get-public-access-block --bucket lydiah-terraform-state-bucket

# Versioning should be Enabled
aws s3api get-bucket-versioning --bucket lydiah-terraform-state-bucket

# Encryption should show AES256
aws s3api get-bucket-encryption --bucket lydiah-terraform-state-bucket
```



## .gitignore

```
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.tfvars
override.tf
override.tf.json
```



## Resources

- [Terraform: Up & Running — Chapter 6: Managing Secrets with Terraform](https://www.terraformupandrunning.com/)
- [AWS Secrets Manager documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform sensitive variables](https://developer.hashicorp.com/terraform/language/values/variables#suppressing-values-in-cli-output)
- [Standalone secrets management guide](https://github.com/LydiahLaw/terraform-secrets-management-guide)
- [Day 13 blog post](https://medium.com/@LydLaw/how-to-handle-sensitive-data-securely-in-terraform-3288979199b2)

---

## Conclusion

This configuration demonstrates how to close all three Terraform secrets leak paths: fetching credentials from Secrets Manager at runtime instead of writing them to configuration files, avoiding default values on sensitive variables, and securing the state file with encryption and restricted access. The `sensitive = true` flag on outputs ensures values never appear in terminal output or pipeline logs. Together these practices form the foundation of production-grade secrets handling in Terraform.
