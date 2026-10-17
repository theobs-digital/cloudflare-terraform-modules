output "tunnel_cloudflared_ids" {
  description = "IDs of the tunnels, by key of `tunnel_cloudflareds`. A public hostname of a tunnel needs a CNAME record to `<id>.cfargotunnel.com`."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.this : key => tunnel.id }
}

output "tunnel_cloudflared_tokens" {
  description = "Tokens that run the tunnels with `cloudflared tunnel run`, by key of `tunnel_cloudflareds`. See [Run the tunnel](#run-the-tunnel)."
  value       = { for key, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.this : key => token.token }
  sensitive   = true
}

output "tunnel_cloudflared_virtual_network_ids" {
  description = "IDs of the virtual networks, by key of `tunnel_cloudflared_virtual_networks`, for the `virtual_network_id` of routes, Access applications and device profiles."
  value       = { for key, network in cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this : key => network.id }
}

output "tunnel_cloudflared_route_ids" {
  description = "IDs of the CIDR routes, by key of `tunnel_cloudflared_routes`."
  value       = { for key, route in cloudflare_zero_trust_tunnel_cloudflared_route.this : key => route.id }
}

output "network_hostname_route_ids" {
  description = "IDs of the hostname routes, by key of `network_hostname_routes`."
  value       = { for key, route in cloudflare_zero_trust_network_hostname_route.this : key => route.id }
}

output "tunnel_warp_connector_ids" {
  description = "IDs of the WARP Connectors, by key of `tunnel_warp_connectors`, for the `tunnel_id` of their HA configuration and of CIDR and hostname routes."
  value       = { for key, connector in cloudflare_zero_trust_tunnel_warp_connector.this : key => connector.id }
}

output "tunnel_warp_connector_tokens" {
  description = "Tokens that register hosts as WARP Connectors with `warp-cli connector new`, by key of `tunnel_warp_connectors`. See [Run a WARP Connector](#run-a-warp-connector)."
  value       = { for key, token in data.cloudflare_zero_trust_tunnel_warp_connector_token.this : key => token.token }
  sensitive   = true
}
