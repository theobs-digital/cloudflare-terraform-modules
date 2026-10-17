# Changelog

All notable changes to the `cloudflare-zero-trust-networks` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-networks/vX.Y.Z`.

## [Unreleased]

## [1.0.0] - 2026-10-18

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- `account_id`, the account of every resource of the module
- Cloudflare Tunnels: map `tunnel_cloudflareds` with the attributes of `cloudflare_zero_trust_tunnel_cloudflared`, and outputs `tunnel_cloudflared_ids` and `tunnel_cloudflared_tokens` (sensitive), read from `cloudflare_zero_trust_tunnel_cloudflared_token`
- Remote configuration of tunnels: map `tunnel_cloudflared_configs` with the attributes of `cloudflare_zero_trust_tunnel_cloudflared_config`, ingress rules and origin request settings
- Virtual networks: map `tunnel_cloudflared_virtual_networks` with the attributes of `cloudflare_zero_trust_tunnel_cloudflared_virtual_network`, and output `tunnel_cloudflared_virtual_network_ids`
- CIDR routes: map `tunnel_cloudflared_routes` with the attributes of `cloudflare_zero_trust_tunnel_cloudflared_route`, and output `tunnel_cloudflared_route_ids`
- Hostname routes: map `network_hostname_routes` with the attributes of `cloudflare_zero_trust_network_hostname_route`, `hostname` and `tunnel_id` required, and output `network_hostname_route_ids`
- WARP Connectors (Mesh nodes): map `tunnel_warp_connectors` with the attributes of `cloudflare_zero_trust_tunnel_warp_connector`, and outputs `tunnel_warp_connector_ids` and `tunnel_warp_connector_tokens` (sensitive), read from `cloudflare_zero_trust_tunnel_warp_connector_token`
- HA configuration of WARP Connectors: map `tunnel_warp_connector_configs` with the attributes of `cloudflare_zero_trust_tunnel_warp_connector_config`, `ha_mode` and virtual IPs or AWS network interface
- Connectivity settings of the account with `connectivity_settings`, the attributes of `cloudflare_zero_trust_connectivity_settings`, left alone when `null`
- Examples `basic`, `complete` and `import`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/compare/cloudflare-zero-trust-networks/v1.0.0...main
[1.0.0]: https://github.com/theobs-digital/cloudflare-terraform-modules/releases/tag/cloudflare-zero-trust-networks/v1.0.0
