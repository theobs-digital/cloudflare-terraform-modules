# Changelog

All notable changes to the `cloudflare-zero-trust-access` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-access/vX.Y.Z`.

## [Unreleased]

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- Zero Trust organization with `organization`, every attribute of `cloudflare_zero_trust_organization`, adopted by import
- Identity providers: map `access_identity_providers` with the attributes of `cloudflare_zero_trust_access_identity_provider`, and outputs `access_identity_provider_ids` and `access_identity_provider_scim_configs` (sensitive)
- Access groups and reusable policies: maps `access_groups` and `access_policies` with the attributes of `cloudflare_zero_trust_access_group` and `cloudflare_zero_trust_access_policy`, and outputs `access_group_ids` and `access_policy_ids`
- Access applications of the 14 types: map `access_applications` with the attributes of `cloudflare_zero_trust_access_application`, reusable policies by ID or, for infrastructure applications, policies written inside them, and outputs `access_application_ids`, `access_application_auds` and `access_application_saas_apps` (sensitive)

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/commits/main/cloudflare-zero-trust-access
