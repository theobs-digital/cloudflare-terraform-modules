variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization."
  type        = string
}

variable "device_settings" {
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

variable "device_default_profile" {
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

variable "device_default_profile_local_domain_fallback" {
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

variable "device_default_profile_certificates" {
  description = "Device client certificates, one entry per zone, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_default_profile_certificates` under the same names. Removing an entry changes nothing in Cloudflare: apply `enabled = false` first to turn the certificate off, see [Device certificates](#device-certificates)."
  type = map(object({
    enabled = bool
    zone_id = string
  }))
  default = {}
}

variable "device_custom_profiles" {
  description = "Custom device profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile` under the same names. Cloudflare requires `match` and `precedence` to create a profile (error 2072), and refuses a `precedence` that another custom profile holds (error 2070): reorder through values no profile holds. Changing `profile_type` replaces the profile, see [Custom profiles](#custom-profiles)."
  type = map(object({
    name              = string
    allow_mode_switch = optional(bool)
    allow_updates     = optional(bool)
    allowed_to_leave  = optional(bool)
    auto_connect      = optional(number)
    browser_extension_config = optional(object({
      proxy_control = string
      proxy_enabled = bool
    }))
    captive_portal        = optional(number)
    description           = optional(string)
    disable_auto_fallback = optional(bool)
    dns_search_suffixes = optional(list(object({
      suffix      = string
      description = optional(string)
    })))
    enabled = optional(bool)
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
    match                          = optional(string)
    precedence                     = optional(number)
    profile_type                   = optional(string)
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
  }))
  default = {}
}

variable "device_custom_profile_local_domain_fallbacks" {
  description = "Local domain fallbacks of custom profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile_local_domain_fallback` under the same names. Take `policy_id` from the `device_custom_profile_ids` output. `domains` replaces the whole list of the profile, Cloudflare's default domains included. Removing an entry changes nothing in Cloudflare, see [Local domain fallback of custom profiles](#local-domain-fallback-of-custom-profiles)."
  type = map(object({
    domains = set(object({
      suffix      = string
      description = optional(string)
      dns_server  = optional(list(string))
    }))
    policy_id = string
  }))
  default = {}
}

variable "device_managed_networks" {
  description = "Managed networks, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_managed_networks` under the same names. `config.sha256` defaults to `\"\"`, which Cloudflare returns for a network without fingerprint. Custom profiles match a network by its `name`, which Cloudflare does not check, see [Managed networks](#managed-networks)."
  type = map(object({
    config = object({
      tls_sockaddr = string
      sha256       = optional(string, "")
    })
    name = string
    type = string
  }))
  default = {}
}

variable "device_posture_integrations" {
  description = "Device posture integrations with third-party providers, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_posture_integration` under the same names. Cloudflare checks the credentials with the provider when it creates the integration, and creates nothing if they fail (error 2046). Pass `config.client_secret`, `config.client_key` and `config.access_client_secret` from sensitive variables, without marking the map sensitive, see [Device posture integrations](#device-posture-integrations)."
  type = map(object({
    config = object({
      access_client_id     = optional(string)
      access_client_secret = optional(string)
      api_url              = optional(string)
      auth_url             = optional(string)
      client_id            = optional(string)
      client_key           = optional(string)
      client_secret        = optional(string)
      customer_id          = optional(string)
    })
    interval = string
    name     = string
    type     = string
  }))
  default = {}
}

variable "device_posture_rules" {
  description = "Device posture rules, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_posture_rule` under the same names. `input` takes the fields of the rule `type`; take `input.connection_id` from the `device_posture_integration_ids` output. Leave `input.operating_system` out: Cloudflare drops it, and each plan shows it again. Write `schedule`, `5m` by default, or an imported rule plans a change. Removing `description` keeps it in Cloudflare, see [Device posture rules](#device-posture-rules)."
  type = map(object({
    type        = string
    description = optional(string)
    expiration  = optional(string)
    input = optional(object({
      active_threats     = optional(number)
      auth_state         = optional(list(string))
      certificate_id     = optional(string)
      check_disks        = optional(list(string))
      check_private_key  = optional(bool)
      cn                 = optional(string)
      compliance_status  = optional(string)
      connection_id      = optional(string)
      count_operator     = optional(string)
      domain             = optional(string)
      eid_last_seen      = optional(string)
      enabled            = optional(bool)
      exists             = optional(bool)
      extended_key_usage = optional(list(string))
      id                 = optional(string)
      infected           = optional(bool)
      is_active          = optional(bool)
      issue_count        = optional(string)
      last_seen          = optional(string)
      locations = optional(object({
        paths        = optional(list(string))
        trust_stores = optional(list(string))
      }))
      network_status            = optional(string)
      operating_system          = optional(string)
      operational_state         = optional(string)
      operator                  = optional(string)
      os                        = optional(string)
      os_distro_name            = optional(string)
      os_distro_revision        = optional(string)
      os_version_extra          = optional(string)
      overall                   = optional(string)
      path                      = optional(string)
      require_all               = optional(bool)
      risk_level                = optional(string)
      score                     = optional(number)
      score_operator            = optional(string)
      sensor_config             = optional(string)
      sha256                    = optional(string)
      state                     = optional(string)
      subject_alternative_names = optional(list(string))
      thumbprint                = optional(string)
      total_score               = optional(number)
      update_window_days        = optional(number)
      version                   = optional(string)
      version_operator          = optional(string)
    }))
    match = optional(list(object({
      platform = optional(string)
    })))
    name     = optional(string)
    schedule = optional(string)
  }))
  default = {}
}
