output "device_custom_profile_ids" {
  description = "IDs of the test custom profiles, by key."
  value       = module.devices.device_custom_profile_ids
}

output "device_posture_rule_ids" {
  description = "IDs of the test posture rules, by key."
  value       = module.devices.device_posture_rule_ids
}
