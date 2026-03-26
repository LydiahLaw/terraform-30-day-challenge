variable "user_names" {
  description = "List of IAM usernames to create"
  type        = list(string)
  default     = ["grace", "amara", "wanjiku"]
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}