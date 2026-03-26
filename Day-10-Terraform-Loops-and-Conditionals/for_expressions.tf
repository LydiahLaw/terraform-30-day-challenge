output "upper_user_names" {
  description = "All usernames in uppercase"
  value       = [for name in ["grace", "amara", "wanjiku"] : upper(name)]
}

output "user_arns" {
  description = "Map of username to ARN for all for_each IAM users"
  value       = { for name, user in aws_iam_user.map_example : name => user.arn }
}