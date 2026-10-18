# Changelog

All notable changes to the `cloudflare-zero-trust-devices` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-devices/vX.Y.Z`.

## [Unreleased]

## [1.0.0] - 2026-10-18

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- Device settings of the account with `device_settings`, every attribute of `cloudflare_zero_trust_device_settings`
- Default profile with `device_default_profile`, adopted by import, and output `device_default_profile_policy_id`
- Local domain fallback of the default profile with `device_default_profile_local_domain_fallback`, updated after the profile
- Device client certificates by zone: map `device_default_profile_certificates` with the attributes of `cloudflare_zero_trust_device_default_profile_certificates`
- Custom profiles: map `device_custom_profiles` with the attributes of `cloudflare_zero_trust_device_custom_profile`, and output `device_custom_profile_ids`
- Local domain fallbacks of custom profiles: map `device_custom_profile_local_domain_fallbacks`, updated after every custom profile, and output `device_custom_profile_local_domain_fallback_ids`
- Managed networks: map `device_managed_networks` with the attributes of `cloudflare_zero_trust_device_managed_networks`, an empty `config.sha256` by default, and output `device_managed_network_ids`
- Device posture integrations and rules: maps `device_posture_integrations` and `device_posture_rules` with the attributes of `cloudflare_zero_trust_device_posture_integration` and `cloudflare_zero_trust_device_posture_rule`, and outputs `device_posture_integration_ids` and `device_posture_rule_ids`
- Device subnets and IP profiles: maps `device_subnets`, created before the subnet they replace, and `device_ip_profiles`, with the attributes of `cloudflare_zero_trust_device_subnet` and `cloudflare_zero_trust_device_ip_profile`, and outputs `device_subnet_ids` and `device_ip_profile_ids`
- Deployment groups: map `device_deployment_groups` with the attributes of `cloudflare_zero_trust_device_deployment_groups`, and output `device_deployment_group_ids`
- Examples `basic`, `complete` and `import`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-zero-trust-devices/v1.0.0...main
[1.0.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/releases/tag/cloudflare-zero-trust-devices/v1.0.0
