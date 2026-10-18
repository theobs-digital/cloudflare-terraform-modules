variable "account_id" {
  description = "ID of the Cloudflare account that owns the tunnels, WARP Connectors and networks."
  type        = string
}

variable "warp_connector_ids" {
  description = "IDs of the existing WARP Connectors, by key of local.warp_connectors, from Networking > Mesh in the dashboard. Provider 5.28.0 cannot look them up by name: its data sources of WARP Connectors fail with \"RFC3339 string value is null\" (provider issue #7417)."
  type        = map(string)
  default     = {}
}
