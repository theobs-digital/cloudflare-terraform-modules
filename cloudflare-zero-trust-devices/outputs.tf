output "device_custom_profile_ids" {
  description = "IDs of the custom profiles, by key of `device_custom_profiles`: the `policy_id` that `device_custom_profile_local_domain_fallbacks` takes."
  value       = { for key, profile in cloudflare_zero_trust_device_custom_profile.this : key => profile.id }
}

output "device_custom_profile_local_domain_fallback_ids" {
  description = "IDs of the local domain fallbacks of custom profiles, by key of `device_custom_profile_local_domain_fallbacks`. Each one is the ID of its profile."
  value       = { for key, fallback in cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this : key => fallback.id }
}

output "device_managed_network_ids" {
  description = "IDs of the managed networks, by key of `device_managed_networks`."
  value       = { for key, network in cloudflare_zero_trust_device_managed_networks.this : key => network.id }
}

output "device_posture_integration_ids" {
  description = "IDs of the device posture integrations, by key of `device_posture_integrations`: the `input.connection_id` of a rule that checks a third-party provider."
  value       = { for key, integration in cloudflare_zero_trust_device_posture_integration.this : key => integration.id }
}

output "device_posture_rule_ids" {
  description = "IDs of the device posture rules, by key of `device_posture_rules`, for the `device_posture` rules of Access groups and policies and the `device_posture.checks.passed` expressions of Gateway policies."
  value       = { for key, rule in cloudflare_zero_trust_device_posture_rule.this : key => rule.id }
}
