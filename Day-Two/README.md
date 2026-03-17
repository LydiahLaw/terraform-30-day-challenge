# Day 02 - Setting Up Your Terraform Environment

## What am I here to do today?

Day 2 is about verifying that the environment set up on Day 1 is fully working and understanding
how the tools connect to each other. The focus shifts from installation to validation 
confirming that Terraform can actually authenticate with AWS and is ready to deploy
real infrastructure.

---

## Tasks Completed

1. **Environment Validation**
   - Ran all four validation commands and confirmed clean output
   - Verified IAM user credentials are correctly configured via shared credentials file
   - Confirmed default region is set to `eu-central-1`

2. **Reading**
   - Read Chapter 2 of *Terraform: Up & Running* by Yevgeniy Brikman
   - Focus areas: AWS account setup, Terraform installation, and how Terraform
     authenticates with AWS

3. **Blog Post**
   - Published: *Step-by-Step Guide to Setting Up Terraform, AWS CLI, and Your AWS Environment*
   - Link: https://medium.com/@LydLaw/step-by-step-guide-to-setting-up-terraform-aws-cli-and-your-aws-environment-626aace27599

4. **Social Media**
   - Shared Day 2 progress on LinkedIn
   - Link: 

---

## Setup Validation
```bash
$ aws --version
aws-cli/2.31.29 Python/3.13.9 Windows/10 exe/AMD64
```
```bash
$ aws configure list
NAME        VALUE                    TYPE                    LOCATION
profile     <not set>                None                    None
access_key  ****************LI4R     shared-credentials-file
secret_key  ****************+3be     shared-credentials-file
region      eu-central-1             config-file             ~/.aws/config
```

<img width="1366" height="768" alt="aws version" src="https://github.com/user-attachments/assets/f85aee01-7aa4-4040-b587-101903ab1a80" />

```bash
$ aws sts get-caller-identity
{
    "UserId": "AIDA4F*********",
    "Account": "835********4",
    "Arn": "arn:aws:iam::835*********:user/terraform"
}
```
<img width="1366" height="768" alt="access keys" src="https://github.com/user-attachments/assets/bc2d9a69-faaf-4483-badb-852b4df08cd2" />

---

## VS Code Extensions

- HashiCorp Terraform
- AWS Toolkit

---
![Uploading extensions.png…]()


## Chapter 2 Learnings

**How Terraform authenticates with AWS**

Terraform does not have its own authentication system. It uses the same credential
chain as the AWS CLI and SDKs. When you run a Terraform command, it looks for
credentials in this order: environment variables (`AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`), then the shared credentials file at
`~/.aws/credentials`, then IAM roles attached to the resource running Terraform.

In my setup, credentials are stored in the shared credentials file, which is
what `aws configure` creates automatically. The `aws configure list` output
confirms this — the `TYPE` column shows `shared-credentials-file` for both
the access key and secret key.

**Why not use the root account?**

The root user has unrestricted access to everything in the AWS account — billing,
IAM, all services. If those credentials were leaked or misused, the damage would
be total. A dedicated IAM user like `terraform` can be scoped to only what
Terraform needs, and if something goes wrong, the blast radius is contained.
The book makes this point clearly: create the IAM user immediately after
setting up the account, then never use root credentials for day-to-day work.

**Declarative vs procedural**

Chapter 2 reinforces something important about how Terraform works. You describe
the end state you want — one EC2 instance of type t2.micro with a specific AMI —
and Terraform figures out the API calls needed to get there. This is different
from writing a script that runs steps in order. If the resource already exists,
Terraform compares what is deployed against what is in the code and only makes
the difference. That `Refreshing state...` line in the apply output is Terraform
doing exactly that check.

**The .gitignore pattern**

The book recommends committing `main.tf` and `.terraform.lock.hcl` but ignoring
the `.terraform` folder and all `*.tfstate` files. The `.terraform` folder is
a scratch directory for downloaded provider plugins — it can be regenerated with
`terraform init`. State files contain sensitive data about real infrastructure
and should never be in a public repository.

---

## Setup Challenges

No blockers today. Environment was already configured from Day 1. Day 2 was
used to validate everything and deepen understanding of how the credential chain
works.

---

## Next Steps

- Write the first Terraform configuration file
- Deploy a single EC2 instance using `terraform init`, `terraform plan`,
  and `terraform apply`
- Understand how Terraform state tracks what it has already created
