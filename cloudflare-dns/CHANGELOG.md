# Changelog

All notable changes to the `cloudflare-dns` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-dns/vX.Y.Z`.

## [Unreleased]

## [1.0.0] - 2026-10-11

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.27
- Zone: `account_id`, `name`, `type`, `paused` and `vanity_name_servers`
- Adoption of an existing zone with `create_zone = false`, looked up by name
- Outputs `zone_id`, `name`, `status`, `name_servers` and `verification_key`
- Records: map `records` with the attributes of `cloudflare_dns_record`, and output `record_ids`
- DNS settings with `dns_settings`, every attribute of `cloudflare_zone_dns_settings` but the deprecated `foundation_dns`, whose changes are ignored
- DNSSEC with `dnssec`, and the `dnssec` output with the DS and DNSKEY fields to give the registrar
- Examples `basic`, `complete` and `import`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-dns/v1.0.0...main
[1.0.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/releases/tag/cloudflare-dns/v1.0.0
