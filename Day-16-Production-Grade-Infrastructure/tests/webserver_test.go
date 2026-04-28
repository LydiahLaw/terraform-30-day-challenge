package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/http-helper"
)

func TestWebserverCluster(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../", // points to your Day 16 root

		Vars: map[string]interface{}{
			"cluster_name":  "test-cluster",
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	url := "http://" + albDnsName

	http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello", 30, 10*time.Second)
}