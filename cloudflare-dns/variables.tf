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

variable "records" {
  description = "DNS records of the zone, by a key of your choice. The key only names the record in the state: keep it stable, since renaming a key replaces the record. Each record takes the attributes of `cloudflare_dns_record` under the same names, and `ttl` defaults to `1` (automatic). Set `content` for A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR and TXT records, `data` for the other types."
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 1)
    content = optional(string)
    data = optional(object({
      algorithm      = optional(number)
      altitude       = optional(number)
      certificate    = optional(string)
      digest         = optional(string)
      digest_type    = optional(number)
      fingerprint    = optional(string)
      flags          = optional(any)
      key_tag        = optional(number)
      lat_degrees    = optional(number)
      lat_direction  = optional(string)
      lat_minutes    = optional(number)
      lat_seconds    = optional(number)
      long_degrees   = optional(number)
      long_direction = optional(string)
      long_minutes   = optional(number)
      long_seconds   = optional(number)
      matching_type  = optional(number)
      order          = optional(number)
      port           = optional(number)
      precision_horz = optional(number)
      precision_vert = optional(number)
      preference     = optional(number)
      priority       = optional(number)
      protocol       = optional(number)
      public_key     = optional(string)
      regex          = optional(string)
      replacement    = optional(string)
      selector       = optional(number)
      service        = optional(string)
      size           = optional(number)
      tag            = optional(string)
      target         = optional(string)
      type           = optional(number)
      usage          = optional(number)
      value          = optional(string)
      weight         = optional(number)
    }))
    proxied  = optional(bool)
    priority = optional(number)
    comment  = optional(string)
    tags     = optional(set(string))
    settings = optional(object({
      flatten_cname = optional(bool)
      ipv4_only     = optional(bool)
      ipv6_only     = optional(bool)
    }))
    private_routing         = optional(bool)
    include_shadow_metadata = optional(bool)
  }))
  default = {}
}
