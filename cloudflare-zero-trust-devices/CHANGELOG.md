# Changelog

All notable changes to the `cloudflare-zero-trust-devices` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-devices/vX.Y.Z`.

## [Unreleased]

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- Device settings of the account with `device_settings`
- Default profile with `device_default_profile`, and its local domain fallback with `device_default_profile_local_domain_fallback`, updated after the profile
- Device client certificates by zone with `device_default_profile_certificates`
- Custom profiles with `device_custom_profiles`, and their local domain fallbacks with `device_custom_profile_local_domain_fallbacks`, updated after the profiles
- Managed networks with `device_managed_networks`, with an empty `config.sha256` by default
- Outputs `device_custom_profile_ids`, `device_custom_profile_local_domain_fallback_ids` and `device_managed_network_ids`
- Device posture integrations with `device_posture_integrations`, and device posture rules with `device_posture_rules`
- Outputs `device_posture_integration_ids` and `device_posture_rule_ids`
- Device subnets with `device_subnets`, created before the subnet they replace, and device IP profiles with `device_ip_profiles`
- Deployment groups with `device_deployment_groups`
- Outputs `device_subnet_ids`, `device_ip_profile_ids`, `device_deployment_group_ids` and `device_default_profile_policy_id`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/commits/main/cloudflare-zero-trust-devices
