# Day 15: Working with Multiple Providers - Part 2

## Overview

This project covers advanced provider scenarios in Terraform: writing modules that accept provider configurations from their callers, deploying Docker containers locally using the Docker provider, and provisioning a full EKS cluster with a Kubernetes workload running on top of it. Three separate deployments, each in its own subfolder.

## Project structure

```
Day-15-Working-With-Multiple-Providers-Part-2/
├── task3-multi-region-module/
│   ├── modules/
│   │   └── multi-region-app/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf
│   ├── backend.tf
│   └── outputs.tf
├── task4-docker/
│   └── main.tf
└── task5-eks/
    ├── main.tf
    ├── backend.tf
    └── outputs.tf
```

## Task 3 — Provider-aware modules

A module cannot define its own provider blocks when it needs to deploy across multiple regions or accounts. Doing so locks the module to a specific target and makes it impossible to reuse. The correct pattern is for the module to declare which providers it expects using configuration_aliases, and for the caller to pass them in via a providers map.

The module declares its expected providers:

```hcl
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.app_name}-primary-day15"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.app_name}-replica-day15"
}
```

The root configuration defines the providers and wires them into the module:

```hcl
provider "aws" {
  alias  = "primary"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "replica"
  region = "eu-west-1"
}

module "multi_region_app" {
  source   = "./modules/multi-region-app"
  app_name = "lydiah"

  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
```

Apply output confirmed two S3 buckets created — one in eu-central-1 and one in eu-west-1 — from a single module call.

## Task 4 — Docker provider

The Docker provider manages local Docker containers. It is a community provider maintained by kreuzwerker, not HashiCorp — reflected in the self-signed notice during terraform init. Docker Desktop must be running before initialising.

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "terraform-nginx"

  ports {
    internal = 80
    external = 8080
  }
}
```

After apply, nginx was confirmed serving at http://localhost:8080. Destroy removed the container and image cleanly.

## Task 5 — EKS cluster and Kubernetes deployment

The most complex deployment of the challenge. A full EKS cluster provisioned using the official terraform-aws-modules/eks module, with a VPC, managed node group, and an nginx deployment applied via the Kubernetes provider.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name            = "eks-vpc-day15"
  cidr            = "10.0.0.0/16"
  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-challenge-cluster"
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"]
    }
  }
}
```

The Kubernetes provider authenticates to the cluster using aws eks get-token via an exec block — no static credentials stored anywhere:

```hcl
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
```

Deployment confirmed via CLI:

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           6m10s
```

## Issues encountered

cluster_version = "1.29" failed with an unsupported AMI error in eu-central-1 — the version is no longer supported for new node groups. Fixed by updating to 1.32.

The Kubernetes provider returned Unauthorized on the first apply attempt after the cluster was ready. Fixed by creating an EKS access entry granting the IAM user AmazonEKSClusterAdminPolicy, then waiting for permissions to propagate.

During destroy, the Kubernetes provider threw Unauthorized because it tried to reach a cluster that was already partially destroyed. Fixed by removing the Kubernetes deployment from state with terraform state rm kubernetes_deployment.nginx before running destroy again.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0
- Docker Desktop running locally (Task 4 only)
- kubectl installed (Task 5 verification)
- S3 bucket for remote state: lydiah-terraform-state-bucket
- DynamoDB table for state locking: terraform-state-locks

## Resources

- [Terraform: Up & Running — Chapter 7](https://www.terraformupandrunning.com/)
- [AWS EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [AWS VPC Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [kreuzwerker Docker provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
- [Day 15 blog post](https://medium.com/@LydLaw)

## Conclusion

Provider-aware modules built with configuration_aliases and the providers map are the correct pattern for reusable multi-region and multi-account infrastructure. The caller controls the target — the module stays generic. The Docker and Kubernetes providers extend this same model beyond AWS, showing that Terraform's provider system works consistently across platforms.
