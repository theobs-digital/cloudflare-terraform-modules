output "unmatched" {
  description = "Keys of the entries that match no existing object, by kind, which the plan creates instead of importing them."
  value = {
    custom_profiles   = [for key, id in local.existing_custom_profile_ids : key if id == null]
    managed_networks  = [for key, id in local.existing_managed_network_ids : key if id == null]
    posture_rules     = [for key, id in local.existing_posture_rule_ids : key if id == null]
    subnets           = [for key in keys(local.subnets) : key if !contains(keys(var.subnet_ids), key)]
    ip_profiles       = [for key, id in local.existing_ip_profile_ids : key if id == null]
    deployment_groups = [for key in keys(local.deployment_groups) : key if !contains(keys(var.deployment_group_ids), key)]
  }
}
