variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization."
  type        = string
}

variable "zone_id" {
  description = "ID of the zone where WARP installs its client certificate."
  type        = string
}

variable "serial_number_list_id" {
  description = "ID of a Gateway list of type SERIAL, such as the list_ids output of the cloudflare-zero-trust-gateway module."
  type        = string
}

variable "client_ca_certificate_id" {
  description = "ID of the cloudflare_mtls_certificate that holds the CA of client certificates."
  type        = string
}

variable "posture_service_client_id" {
  description = "Client ID of the Access service token that Cloudflare sends to the posture service."
  type        = string
}

variable "posture_service_client_secret" {
  description = "Client secret of that service token."
  type        = string
  sensitive   = true
}

variable "client_versions" {
  description = "Full release numbers of the WARP client for each ring, from the Cloudflare One Client changelog."
  type = object({
    ring0 = string
    ring1 = string
  })
  default = {
    ring0 = "2026.8.2110.0"
    ring1 = "2026.8.2100.0"
  }
}
