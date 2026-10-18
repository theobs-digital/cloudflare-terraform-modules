output "tunnel_id" {
  description = "ID of the tunnel. wiki.example.com needs a proxied CNAME record to <id>.cfargotunnel.com."
  value       = module.networks.tunnel_cloudflared_ids["office"]
}

output "tunnel_token" {
  description = "Token that runs the tunnel, for cloudflared on the office network."
  value       = module.networks.tunnel_cloudflared_tokens["office"]
  sensitive   = true
}
