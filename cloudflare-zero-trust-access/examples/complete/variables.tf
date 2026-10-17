variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization."
  type        = string
}

variable "entra_client_secret" {
  description = "Client secret of the Access application registered in Microsoft Entra ID."
  type        = string
  sensitive   = true
}

variable "client_ca_certificate" {
  description = "PEM of the certificate authority that signs the client certificates, with its chain for an intermediate CA."
  type        = string
}
