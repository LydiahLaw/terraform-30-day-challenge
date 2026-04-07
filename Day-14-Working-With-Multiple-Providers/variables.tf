variable "primary_bucket_name" {
  description = "Name of the primary S3 bucket in eu-central-1"
  type        = string
  default     = "lydiah-primary-bucket-day14"
}

variable "replica_bucket_name" {
  description = "Name of the replica S3 bucket in eu-west-1"
  type        = string
  default     = "lydiah-replica-bucket-day14"
}
