# Changelog

All notable changes to the `cloudflare-dns` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-dns/vX.Y.Z`.

## [Unreleased]

## [1.2.0] - 2026-10-17

No change to the module's code: documentation, tests and CI only.

### Added

- Tests against a real zone, in `tests-real`: 18 records of 14 types under `tf-test.<zone>`, SPF, DMARC and a 2048-bit DKIM key among them, then a plan that must show no change, an update in place and a second plan. `terraform test` runs them only when asked
- Workflow `Real zone tests`: runs them every day with the newest provider 5.x, after deleting what a run cut short left under `tf-test.<zone>`
- Workflow `Checks`: on every pull request and push to `main`, the pre-commit hooks and the mock tests of every module, without any secret
- README guides: share values between records with `merge()`, keep the records in YAML, and email records (SPF, DKIM and DMARC)

### Changed

- README rewritten: quick start, every input as a commented HCL block, warnings by severity, guides, and the terraform-docs reference folded at the end
- README: Cloudflare also rewrites the `target` of HTTPS and SVCB records and splits a quoted TXT string over 255 characters; a misspelled attribute is dropped without an error; provider checked with 5.27.0 and 5.28.0
- One `.terraform-docs.yml` at the repository root for every module

## [1.1.0] - 2026-10-17

### Added

- Plan-time checks on `records`, which the provider leaves to the apply: a record needs `content` or `data`, and a proxied record `ttl = 1`

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

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-dns/v1.2.0...main
[1.2.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-dns/v1.1.0...cloudflare-dns/v1.2.0
[1.1.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-dns/v1.0.0...cloudflare-dns/v1.1.0
[1.0.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/releases/tag/cloudflare-dns/v1.0.0
