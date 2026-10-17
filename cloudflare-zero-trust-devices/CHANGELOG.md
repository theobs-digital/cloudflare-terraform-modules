# Changelog

All notable changes to the `cloudflare-zero-trust-devices` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-devices/vX.Y.Z`.

## [Unreleased]

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- Device settings of the account with `settings`
- Default profile with `default_profile`, and its local domain fallback with `default_profile_local_domain_fallback`, updated after the profile
- Device client certificates by zone with `default_profile_certificates`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/commits/main/cloudflare-zero-trust-devices
