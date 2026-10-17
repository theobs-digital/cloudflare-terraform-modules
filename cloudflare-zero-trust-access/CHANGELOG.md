# Changelog

All notable changes to the `cloudflare-zero-trust-access` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-access/vX.Y.Z`.

## [Unreleased]

## [1.0.0] - 2026-10-17

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- Zero Trust organization with `organization`, every attribute of `cloudflare_zero_trust_organization`, adopted by import
- Identity providers: map `access_identity_providers` with the attributes of `cloudflare_zero_trust_access_identity_provider`, and outputs `access_identity_provider_ids` and `access_identity_provider_scim_configs` (sensitive)
- Access groups and reusable policies: maps `access_groups` and `access_policies` with the attributes of `cloudflare_zero_trust_access_group` and `cloudflare_zero_trust_access_policy`, and outputs `access_group_ids` and `access_policy_ids`
- Access applications of the 14 types: map `access_applications` with the attributes of `cloudflare_zero_trust_access_application`, reusable policies by ID or, for infrastructure applications, policies written inside them, and outputs `access_application_ids`, `access_application_auds` and `access_application_saas_apps` (sensitive)
- Service tokens: map `access_service_tokens` with the attributes of `cloudflare_zero_trust_access_service_token`, and outputs `access_service_token_ids`, `access_service_token_client_ids` and `access_service_token_client_secrets` (sensitive)
- mTLS: map `access_mtls_certificates` with the attributes of `cloudflare_zero_trust_access_mtls_certificate`, output `access_mtls_certificate_ids`, and the account's hostname settings with `access_mtls_hostname_settings`, adopted by import
- Short-lived SSH certificate authorities: map `access_short_lived_certificates` with the `app_id` of `cloudflare_zero_trust_access_short_lived_certificate`, and output `access_short_lived_certificate_public_keys`
- Tags and custom pages: maps `access_tags` and `access_custom_pages` with the attributes of `cloudflare_zero_trust_access_tag` and `cloudflare_zero_trust_access_custom_page`, and outputs `access_tag_ids` and `access_custom_page_ids`
- Rotation of the signing keys with `access_key_configuration`, the attribute of `cloudflare_zero_trust_access_key_configuration`, adopted by import
- Infrastructure targets: map `access_infrastructure_targets` with the attributes of `cloudflare_zero_trust_access_infrastructure_target`, and output `access_infrastructure_target_ids`
- MCP servers and portals of AI controls: maps `access_ai_controls_mcp_servers` and `access_ai_controls_mcp_portals` with the attributes of `cloudflare_zero_trust_access_ai_controls_mcp_server` and `cloudflare_zero_trust_access_ai_controls_mcp_portal`, and output `access_ai_controls_mcp_server_ids`
- Examples `basic`, `complete` and `import`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-zero-trust-access/v1.0.0...main
[1.0.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/releases/tag/cloudflare-zero-trust-access/v1.0.0
