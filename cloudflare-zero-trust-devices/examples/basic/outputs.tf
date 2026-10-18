output "device_posture_rule_ids" {
  description = "IDs of the posture rules, by key, for the device_posture rules of Access policies."
  value       = module.devices.device_posture_rule_ids
}

output "engineering_profile_id" {
  description = "ID of the Engineering profile."
  value       = module.devices.device_custom_profile_ids["engineering"]
}
