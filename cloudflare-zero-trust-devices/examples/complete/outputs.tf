output "device_posture_rule_ids" {
  description = "IDs of the posture rules, by key, for the device_posture rules of Access policies and the device_posture expressions of Gateway policies."
  value       = module.devices.device_posture_rule_ids
}

output "device_custom_profile_ids" {
  description = "IDs of the custom profiles, by key, for the match of DEX rules."
  value       = module.devices.device_custom_profile_ids
}
