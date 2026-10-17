# Changelog

All notable changes to the `cloudflare-zero-trust-networks` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are tagged `cloudflare-zero-trust-networks/vX.Y.Z`.

## [Unreleased]

### Added

- Requirements: Terraform >= 1.3 and provider `cloudflare/cloudflare` ~> 5.28
- `account_id`, the account of every resource of the module
- `tunnel_cloudflareds`, Cloudflare Tunnels, with their IDs in
  `tunnel_cloudflared_ids` and the tokens that run them in the sensitive
  `tunnel_cloudflared_tokens`
- `tunnel_cloudflared_configs`, the remote configuration of tunnels: ingress
  rules and origin request settings
- `tunnel_cloudflared_virtual_networks`, virtual networks, with their IDs in
  `tunnel_cloudflared_virtual_network_ids`
- `tunnel_cloudflared_routes`, CIDR routes to tunnels, with their IDs in
  `tunnel_cloudflared_route_ids`
- `network_hostname_routes`, hostname routes to tunnels, with their IDs in
  `network_hostname_route_ids`
- `tunnel_warp_connectors`, WARP Connectors (Mesh nodes), with their IDs in
  `tunnel_warp_connector_ids` and the tokens that register their hosts in the
  sensitive `tunnel_warp_connector_tokens`
- `tunnel_warp_connector_configs`, the HA configuration of WARP Connectors:
  `ha_mode`, virtual IPs or AWS network interface
- `connectivity_settings`, the ICMP proxy and WARP-to-WARP settings of the
  account, left alone when `null`

[Unreleased]: https://github.com/theobs-digital/cloudflare-terraform-modules/commits/main/cloudflare-zero-trust-networks
