output "primary_bucket_name" {
  description = "Name of the primary S3 bucket in eu-central-1"
  value       = module.multi_region_app.primary_bucket_name
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket in eu-west-1"
  value       = module.multi_region_app.replica_bucket_name
}
