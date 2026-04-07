module "multi_region_app" {
  source   = "./modules/multi-region-app"
  app_name = "lydiah"

  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
