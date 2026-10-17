output "unmatched" {
  description = "Keys of the entries that match no existing object, by kind, which the plan creates instead of importing them."
  value = {
    identity_providers = [for key, id in local.existing_identity_provider_ids : key if id == null]
    groups             = [for key, id in local.existing_group_ids : key if id == null]
    policies           = [for key, id in local.existing_policy_ids : key if id == null]
    applications       = [for key, id in local.existing_application_ids : key if id == null]
  }
}
