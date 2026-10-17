variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization."
  type        = string
}

variable "settings" {
  description = "Device settings of the account, with the attributes of `cloudflare_zero_trust_device_settings` under the same names. When `null`, the module leaves them alone. Write every field Cloudflare returns: one left out shows as a change to `null` at each plan, which Cloudflare refuses (error 2024). Removing this argument resets the settings, see [Settings](#settings)."
  type = object({
    disable_for_time                      = optional(number)
    external_emergency_signal_enabled     = optional(bool)
    external_emergency_signal_fingerprint = optional(string)
    external_emergency_signal_interval    = optional(string)
    external_emergency_signal_url         = optional(string)
    gateway_proxy_enabled                 = optional(bool)
    gateway_udp_proxy_enabled             = optional(bool)
    root_certificate_installation_enabled = optional(bool)
    use_zt_virtual_ip                     = optional(bool)
  })
  default = null
}

variable "default_profile" {
  description = "Default device profile of the account, with the attributes of `cloudflare_zero_trust_device_default_profile` under the same names. When `null`, the module leaves it alone. Adopt it with an `import` block: without one, the first apply writes the provider default of each attribute left out, such as `tunnel_protocol = \"\"`. Write `exclude` or `include`, `service_mode_v2` and `dns_search_suffixes` as Cloudflare holds them, or each plan shows an empty update. Removing this argument changes nothing in Cloudflare, see [Default profile](#default-profile)."
  type = object({
    allow_mode_switch     = optional(bool)
    allow_updates         = optional(bool)
    allowed_to_leave      = optional(bool)
    auto_connect          = optional(number)
    captive_portal        = optional(number)
    disable_auto_fallback = optional(bool)
    dns_search_suffixes = optional(list(object({
      suffix      = string
      description = optional(string)
    })))
    exclude = optional(list(object({
      address     = optional(string)
      description = optional(string)
      host        = optional(string)
    })))
    exclude_office_ips = optional(bool)
    global_acceleration = optional(object({
      api_endpoints       = list(string)
      enabled             = bool
      masque_endpoints    = list(string)
      wireguard_endpoints = list(string)
    }))
    include = optional(list(object({
      address     = optional(string)
      description = optional(string)
      host        = optional(string)
    })))
    lan_allow_minutes              = optional(number)
    lan_allow_subnet_size          = optional(number)
    register_interface_ip_with_dns = optional(bool)
    sccm_vpn_boundary_support      = optional(bool)
    service_mode_v2 = optional(object({
      mode = optional(string)
      port = optional(number)
    }))
    support_url          = optional(string)
    switch_locked        = optional(bool)
    tunnel_protocol      = optional(string)
    uninstall_protection = optional(bool)
    virtual_networks = optional(object({
      allowed = list(string)
      default = string
    }))
  })
  default = null
}

variable "default_profile_local_domain_fallback" {
  description = "Local domain fallback of the default profile, with the attributes of `cloudflare_zero_trust_device_default_profile_local_domain_fallback` under the same names. When `null`, the module leaves it alone. `domains` replaces the whole list, Cloudflare's default domains included. Removing this argument changes nothing in Cloudflare, see [Local domain fallback](#local-domain-fallback)."
  type = object({
    domains = set(object({
      suffix      = string
      description = optional(string)
      dns_server  = optional(list(string))
    }))
  })
  default = null
}

variable "default_profile_certificates" {
  description = "Device client certificates, one entry per zone, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_default_profile_certificates` under the same names. Removing an entry changes nothing in Cloudflare: apply `enabled = false` first to turn the certificate off, see [Device certificates](#device-certificates)."
  type = map(object({
    enabled = bool
    zone_id = string
  }))
  default = {}
}
