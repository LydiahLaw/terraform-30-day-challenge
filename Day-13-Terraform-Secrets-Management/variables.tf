variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "appdb"
}

variable "db_instance_class" {
  description = "The RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage allocated to the RDS instance in GB"
  type        = number
  default     = 10
}
