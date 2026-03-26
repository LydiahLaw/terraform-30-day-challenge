# Day 09 - Advanced Terraform Module Usage: Versioning, Gotchas, and Reuse Across Environments

## What am I here to do today?

Day 9 goes deeper into modules. Yesterday was about building and calling a
module for the first time. Today is about the rough edges — three specific
module behaviours that cause subtle bugs in real deployments — and the
versioning pattern that makes modules safe to share across a team. By the end
of today the module from Day 8 is version-pinned, lives in its own repository,
and is deployed differently across dev and production.


## Tasks Completed

- Read Chapter 4 of Terraform: Up & Running — pages 115 through 139, focusing
  on module gotchas and module versioning
- Completed Lab 1: Terraform Workspaces
- Completed Lab 2: Terraform Modules
- Documented the three module gotchas with broken and corrected examples
- Created standalone GitHub repository for the webserver-cluster module
- Tagged v0.0.1 as the initial release
- Updated calling configurations to reference versioned GitHub source
- Added custom_tag variable and tagged v0.0.2
- Configured dev to use v0.0.2 and production to stay pinned to v0.0.1
- Ran terraform init in both environments and confirmed correct versions pulled
- Deployed from dev, confirmed cluster reachable, destroyed after confirmation
- Published blog post
- Shared on social media

---

## Project Structure
```
Day-09-Advanced-Terraform-Modules/
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

Module repository: github.com/LydiahLaw/terraform-aws-webserver-cluster

---

## Module Gotchas

**Gotcha 1 — File paths**

Broken:
```hcl
user_data = templatefile("./user-data.sh", {
  server_port = var.server_port
})
```

Corrected:
```hcl
user_data = templatefile("${path.module}/user-data.sh", {
  server_port = var.server_port
})
```

Relative paths resolve from where terraform is run, not from inside the
module. path.module always resolves to the module directory itself.

**Gotcha 2 — Inline blocks vs separate resources**

Broken — mixing inline ingress block with a separate security group rule:
```hcl
resource "aws_security_group" "instance_sg" {
  name = "${var.cluster_name}-instance-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "extra_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.instance_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

Corrected — separate resources only:
```hcl
resource "aws_security_group" "instance_sg" {
  name = "${var.cluster_name}-instance-sg"
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  security_group_id = aws_security_group.instance_sg.id
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

Mixing both causes Terraform to manage the same rule twice. One overwrites
the other. Separate resources are also more flexible — callers can add rules
without modifying the module.

**Gotcha 3 — Module output dependencies**

Broken — depending on the entire module:
```hcl
resource "aws_instance" "app" {
  ami           = "ami-0cebfb1f908092578"
  instance_type = "t2.micro"

  depends_on = [module.webserver_cluster]
}
```

Corrected — referencing a specific output value:
```hcl
resource "aws_instance" "app" {
  ami           = "ami-0cebfb1f908092578"
  instance_type = "t2.micro"
  user_data     = "connect to ${module.webserver_cluster.alb_dns_name}"
}
```

depends_on on a module forces Terraform to evaluate the entire module as a
dependency. Referencing a specific output gives Terraform a precise dependency
to reason about.

---

## Module Versioning

The module from Day 8 was pushed to a standalone repository and tagged:
```bash
git tag -a "v0.0.1" -m "First release of webserver-cluster module"
git push origin main --tags
```

A new input variable custom_tag was added in v0.0.2:
```bash
git tag -a "v0.0.2" -m "Add custom_tag input variable"
git push origin main --tags
```

Tag confirmation:
```bash
git tag -l
v0.0.1
v0.0.2
```

---

## Calling Configurations

Dev — using v0.0.2 to test the latest version:
```hcl
module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=v0.0.2"

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

Production — pinned to v0.0.1, the validated stable version:
```hcl
module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name  = "webservers-production"
  instance_type = "t2.medium"
  min_size      = 4
  max_size      = 10
  server_port   = 80
}
```

Production stays on v0.0.1 until v0.0.2 is validated in dev. The update to
production is a deliberate decision, not an automatic one.

---

## Deployment Confirmation

Deployed from live/dev/services/webserver-cluster using v0.0.2. Cluster came
up with instances behind the ALB and was reachable in the browser. Screenshot
saved. Resources destroyed after confirmation.

---

## Version Pinning Strategy

Without a version pin, the source always pulls whatever is currently on the
default branch. In a team environment, if one engineer updates the module and
another runs terraform apply before reviewing the change, they deploy code they
have not seen. Two engineers running apply minutes apart can end up with
different infrastructure from the same configuration. Pinning to a tag means
the source is immutable — a tag always points to the same commit.

---

## Chapter 4 Learnings

- File paths inside modules must use path.module, not relative paths, because
  Terraform resolves paths from the working directory where commands are run
- Inline blocks and separate resources for the same configuration conflict when
  mixed — pick one pattern per resource type and stay consistent
- depends_on on a module creates a dependency on the entire module, not a
  specific resource — use output references for precise dependency tracking
- Git tags are immutable version markers. Branches are not — a branch source
  can change between two terraform init runs on the same configuration

---

## Challenges and Fixes

Paste what came up during the GitHub source URL setup, terraform init caching,
or tagging here after you complete the steps.

---

## Blog Post

URL: [paste URL]
Covered the three module gotchas with broken and corrected examples, the
versioning workflow from tagging to pinning, all three source URL formats, and
the multi-environment deployment pattern.

## Social Media

URL: [paste URL]
