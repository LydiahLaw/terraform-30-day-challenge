## day-17-manual-testing

### overview

Day 17 shifted the focus from building infrastructure to validating it. Instead of adding new resources, I worked through a structured manual testing process to verify that my existing webserver cluster behaves correctly under real conditions. This included provisioning checks, functional validation, state consistency, regression testing, and cleanup discipline.

This day made one thing clear. Running terraform apply is not proof that your infrastructure works. You need a repeatable way to test and verify behavior.

---

### what i set out to do

The goal was to:

* build a structured manual testing checklist
* execute tests against my infrastructure
* document results clearly
* identify failures and fix them
* enforce cleanup to avoid unnecessary AWS costs

---

### project structure

```bash id="f8n2rb"
Day-17-Manual-Testing/
  main.tf
  manual-test-results.md
```

This setup reuses the standalone module:

```hcl id="q9bzv5"
module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=main"
}
```

---

### manual testing checklist

#### provisioning verification

* terraform init completes without errors
* terraform validate passes
* terraform plan shows expected resources
* terraform apply completes successfully

#### resource correctness

* resources visible in AWS console
* names and tags match configuration
* security group rules match expected setup

#### functional verification

* ALB DNS resolves
* curl returns expected response
* instances pass health checks
* ASG replaces terminated instance

#### state consistency

* terraform plan returns no changes after apply
* state matches deployed infrastructure

#### regression check

* configuration change reflected correctly
* no unexpected changes in plan
* plan clean after re-apply

---

### test execution and results

#### provisioning tests

Test: terraform init completes
Command: terraform init
Expected: initialization successful
Actual: initialization successful
Result: PASS

Test: terraform validate passes
Command: terraform validate
Expected: success
Actual: success
Result: PASS

Test: terraform plan after apply
Command: terraform plan
Expected: no changes
Actual: no changes
Result: PASS

---

#### functional tests

Test: ALB DNS resolves and returns response
Command: curl -s http://webservers-day17-alb-430036926.eu-central-1.elb.amazonaws.com
Expected: HTML response
Actual: <h1>Hello from webservers-day17 - v2</h1>
Result: PASS

Test: ASG replaces terminated instance
Command: manual termination via AWS console
Expected: ASG launches replacement instance
Actual: new instance launched automatically
Result: PASS

---

#### state consistency

Test: terraform plan returns clean state
Command: terraform plan
Expected: no changes
Actual: no changes
Result: PASS

---

#### regression testing

Test: regression test using custom_tag change
Command: terraform plan
Expected: tag updates
Actual: no changes
Result: FAIL
Fix: identified that custom_tag is not used in tagging logic

Test: regression test using cluster_name change
Command: terraform plan
Expected: resource updates
Actual: replacement required but blocked by prevent_destroy
Result: FAIL
Fix: identified lifecycle.prevent_destroy prevents replacement of critical resources

---

### cleanup process

Test: terraform destroy
Command: terraform destroy
Expected: all resources destroyed
Actual: destroy failed due to prevent_destroy
Result: FAIL

Test: cleanup after module update
Command: terraform init -upgrade and terraform destroy
Expected: all resources destroyed
Actual: successful after refreshing module
Result: PASS

verification:

```bash id="rpgmgh"
aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=terraform" --query "Reservations[*].Instances[*].InstanceId"
```

```bash id="7ymxsr"
aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn"
```

Expected result: empty outputs

---

### key insights

* manual testing requires structure, not guesswork
* terraform plan is one of the most important validation tools
* not all configuration changes result in infrastructure updates
* lifecycle rules like prevent_destroy protect infrastructure but can block legitimate changes
* terraform caches modules, changes require reinitialization
* incomplete destroy operations can leave orphaned resources

---

### challenges faced

* regression test initially failed due to unused variable
* lifecycle.prevent_destroy blocked both updates and destroy
* module changes not reflected due to caching
* leftover resources required manual cleanup strategy

---

### conclusion

Day 17 focused on verification and discipline rather than building. The biggest shift was understanding that infrastructure must be tested intentionally, not assumed to work. The failures encountered during testing were the most valuable part, as they revealed real-world scenarios that require careful handling.

This day reinforced that reliable infrastructure is not just built. It is tested, validated, and maintained with clear processes.
