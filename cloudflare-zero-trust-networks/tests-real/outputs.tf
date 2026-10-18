output "tunnel_ids" {
  description = "IDs of the test tunnels, by key."
  value       = module.networks.tunnel_cloudflared_ids
}

output "warp_connector_ids" {
  description = "IDs of the test WARP Connectors, by key."
  value       = module.networks.tunnel_warp_connector_ids
}
