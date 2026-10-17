output "tunnel_cloudflared_ids" {
  description = "IDs of the tunnels, by key of `tunnel_cloudflareds`. A public hostname of a tunnel needs a CNAME record to `<id>.cfargotunnel.com`."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.this : key => tunnel.id }
}

output "tunnel_cloudflared_tokens" {
  description = "Tokens that run the tunnels with `cloudflared tunnel run`, by key of `tunnel_cloudflareds`. See [Run the tunnel](#run-the-tunnel)."
  value       = { for key, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.this : key => token.token }
  sensitive   = true
}
