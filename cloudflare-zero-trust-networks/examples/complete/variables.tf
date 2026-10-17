variable "account_id" {
  description = "ID of the Cloudflare account that owns the tunnels, WARP Connectors and networks."
  type        = string
}

variable "lyon_tunnel_secret" {
  description = "Secret of the lyon tunnel, at least 32 bytes in base64, such as the output of `openssl rand -base64 32`."
  type        = string
  sensitive   = true
}

variable "api_aud" {
  description = "Audience tag (AUD) of the Access application that protects app.example.com/api/, which cloudflared checks before it forwards a request."
  type        = string
}
