variable "account_id" {
  description = "ID of the Cloudflare account that owns the zone."
  type        = string
}

variable "name" {
  description = "Domain name of the zone, such as `example.com`. Changing it replaces the zone."
  type        = string
}

variable "create_zone" {
  description = "Whether the module creates the zone. Set it to `false` when the zone already exists and another configuration manages it: the module then looks the zone up by `name` in the account, manages only its records, DNS settings and DNSSEC, and ignores `type`, `paused` and `vanity_name_servers`."
  type        = bool
  default     = true
}

variable "type" {
  description = "Type of the zone: `full`, `partial`, `secondary` or `internal`. When `null`, the provider sets `full`."
  type        = string
  default     = null
}

variable "paused" {
  description = "Whether the zone only uses Cloudflare DNS, without the security and performance features. When `null`, the provider sets `false`."
  type        = bool
  default     = null
}

variable "vanity_name_servers" {
  description = "Custom name servers of the zone. Business and Enterprise plans only."
  type        = list(string)
  default     = null
}
