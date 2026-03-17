# Day 01 - Environment Setup and Introduction to Terraform

## What am I here to do today?

Today is all about setting up my environment for the 30-Day Terraform Challenge and starting my journey with Infrastructure as Code (IaC). The main goal is to have a fully working Terraform setup on my machine, connect it to AWS, and get ready to build infrastructure safely and efficiently.

---

## Tasks Completed

1. **AWS Account**
   - Created an AWS account (free tier)
   - Set up an IAM user with AdministratorAccess for Terraform
   - Generated Access Key ID and Secret Access Key

2. **Terraform**
   - Installed Terraform v1.14.7 on my local Windows machine
   - Verified installation using:
```bash
     terraform version
```

3. **AWS CLI**
   - Installed AWS CLI
   - Configured credentials:
```bash
     aws configure
```

<img width="1366" height="768" alt="Screenshot (1600)" src="https://github.com/user-attachments/assets/c87cf00b-a168-40a7-a8bc-3dd109fbd36c" />

   - Verified connection using:
```bash
     aws sts get-caller-identity
```
<img width="1366" height="768" alt="Screenshot (1601)" src="https://github.com/user-attachments/assets/04647b35-cceb-4173-a5aa-9a3d96caec12" />

4. **Visual Studio Code**
   - Installed VS Code
   - Added extensions:
     - HashiCorp Terraform
     - AWS Toolkit
   - Set up workspace for all Terraform files

   <img width="1366" height="768" alt="Screenshot (1599)" src="https://github.com/user-attachments/assets/dda6f778-6197-4ef1-9ff7-26e9a9764468" />


5. **Blog Setup**
   - Created a blog on Medium
   - Published first post: *What is Infrastructure as Code and Why It's Transforming DevOps*
   - Covered:
     - What IaC is and the problem it solves
     - Declarative vs imperative approaches
     - Why Terraform is worth learning
     - My goals for the 30-day challenge

     https://medium.com/@lygashiku/what-is-infrastructure-as-code-and-why-its-transforming-devops-af7c8f9cb295

6. **Social Media**
   - Shared Day 1 progress on X
   - Included a link to my blog post and hashtags for the challenge

7. **Reading**
   - Read Chapter 1 of *Terraform: Up & Running* by Yevgeniy Brikman
   - Focus areas: what Terraform is, why infrastructure-as-code matters, and how declarative tooling differs from manual provisioning

---

## Key Commands and Checks
```bash
# Verify Terraform
terraform version

# Verify AWS connection
aws sts get-caller-identity
```

---

## Lessons Learned Today

- Setting up the environment correctly at the start saves a lot of headaches later
- Declarative IaC (Terraform) is very different from manually configuring AWS resources
- Blogging the journey helps with reflection and makes it easier to share knowledge
- Documenting every step ensures the work is portfolio-ready

---

## Next Steps

- Start exploring Terraform basics and writing simple infrastructure code
- Practice creating AWS resources using Terraform
- Continue documenting everything in both the blog and this repo
