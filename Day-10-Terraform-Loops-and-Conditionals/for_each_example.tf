variable "user_set" {
  description = "Set of IAM usernames - keyed, so removal only affects the removed user"
  type        = set(string)
  default     = ["grace", "amara", "wanjiku"]
}

resource "aws_iam_user" "set_example" {
  for_each = var.user_set
  name     = each.value
}

variable "users_map" {
  description = "Map of IAM users with role metadata"
  type = map(object({
    department = string
    level      = string
  }))
  default = {
    grace   = { department = "infrastructure", level = "senior" }
    amara   = { department = "security",        level = "mid" }
    wanjiku = { department = "data",            level = "junior" }
  }
}

resource "aws_iam_user" "map_example" {
  for_each = var.users_map
  name     = each.key
  tags = {
    Department = each.value.department
    Level      = each.value.level
  }
}