output "tunnel_ids" {
  description = "IDs of the tunnels, by key. A public hostname of the paris tunnel needs a proxied CNAME record to <id>.cfargotunnel.com."
  value       = module.networks.tunnel_cloudflared_ids
}

output "tunnel_tokens" {
  description = "Tokens that run the tunnels with cloudflared, by key."
  value       = module.networks.tunnel_cloudflared_tokens
  sensitive   = true
}

output "virtual_network_ids" {
  description = "IDs of the virtual networks, by key, for Access applications and device profiles."
  value       = module.networks.tunnel_cloudflared_virtual_network_ids
}

output "warp_connector_tokens" {
  description = "Tokens that register the hosts of the WARP Connectors, by key."
  value       = module.networks.tunnel_warp_connector_tokens
  sensitive   = true
}
