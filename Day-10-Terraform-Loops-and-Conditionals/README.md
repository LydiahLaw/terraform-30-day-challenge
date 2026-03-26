# Day 10: Terraform Loops and Conditionals

## Overview

This day covers three Terraform meta-arguments and expression types that make
infrastructure code reusable and environment-aware: `count`, `for_each`, and
conditionals using the ternary operator. The webserver cluster module from Days
8 and 9 is refactored to support optional autoscaling and environment-driven
instance sizing, then deployed across dev and production to verify the
conditional behaviour.

## Concepts Covered

**count**
The simplest loop — creates N identical copies of a resource using an index.
The limitation: if you use `count` with a list and remove an item from the
middle, Terraform renumbers all subsequent resources and recreates them. This
is destructive and unexpected.

**for_each**
Solves the ordering problem by keying resources on a map or set value instead
of a numeric index. Removing one entry only touches that specific resource.
Preferred over `count` whenever you are iterating over a collection of named
items.

**for expressions**
Transform collections inline inside resource arguments, outputs, or locals.
They do not create resources — they reshape data. Used here to produce a clean
map of autoscaling policy names to ARNs in the module output.

**Conditionals**
Terraform uses the ternary operator: `condition ? true_value : false_value`.
Combined with `count`, this makes resources optional:
```hcl
count = var.enable_autoscaling ? 1 : 0
```

Combined with `locals`, this centralises environment-driven sizing decisions:
```hcl
locals {
  instance_type = var.environment == "production" ? "t2.medium" : "t2.micro"
}
```

## Module Changes (v0.0.3)

Two new variables added to the standalone module:

- `enable_autoscaling` (bool, default: true) — controls whether scale-out and
  scale-in autoscaling policies are created
- `environment` (string, default: "dev") — drives instance type selection via
  a local

New resources added:

- `aws_autoscaling_policy.scale_out` — created only when `enable_autoscaling = true`
- `aws_autoscaling_policy.scale_in` — created only when `enable_autoscaling = true`

New output added:

- `autoscaling_policy_arns` — a `for` expression producing a map of policy
  name to ARN

## Directory Structure
```
Day-10-Terraform-Loops-and-Conditionals/
├── README.md
├── count_example.tf
├── for_each_example.tf
├── for_expressions.tf
└── live/
    ├── dev/
    │   └── services/
    │       └── webserver-cluster/
    │           ├── main.tf
    │           ├── variables.tf
    │           └── outputs.tf
    └── production/
        └── services/
            └── webserver-cluster/
                ├── main.tf
                ├── variables.tf
                └── outputs.tf
```

## Deployment Results

**Dev** (`enable_autoscaling = false`, `environment = "dev"`)
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name            = "webservers-dev-alb-508599619.eu-central-1.elb.amazonaws.com"
asg_name                = "webservers-dev-asg"
autoscaling_policy_arns = {}
```

**Production** (`enable_autoscaling = true`, `environment = "production"`)
```
Outputs:
alb_dns_name            = "webservers-production-alb-350535575.eu-central-1.elb.amazonaws.com"
asg_name                = "webservers-production-asg"
autoscaling_policy_arns = {
  "webservers-production-scale-out" = "arn:aws:autoscaling:eu-central-1:..."
}
```

The empty map in dev and the populated map in production confirm the
conditional is working correctly.

## Key Takeaway

Use `for_each` over `count` for named resources. Use `count = condition ? 1 : 0`
to make resources optional. Keep conditional logic inside `locals` rather than
scattering ternary operators through resource arguments — it makes the code
easier to read and reason about.

## Module Repository

[terraform-aws-webserver-cluster](https://github.com/LydiahLaw/terraform-aws-webserver-cluster)
— tagged at v0.0.3 for this day.

## Conclusion

Day 10 moves Terraform code from static to expressive. Before today the module
always created the same set of resources regardless of where it was deployed.
After today the same module behaves differently based on two boolean inputs —
no duplicate resource blocks, no environment-specific modules, no copy-paste.
The `for` expression in the output turns a list of resources into a usable map
with a single line. These patterns — conditional creation, for_each keying,
for expression outputs — appear in almost every real-world Terraform codebase
and are worth understanding deeply before moving on.