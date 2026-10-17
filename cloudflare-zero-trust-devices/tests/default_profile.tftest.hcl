mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "default_profile_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_default_profile.this) == 0
    error_message = "Without default_profile, the module must not manage the default profile."
  }

  assert {
    condition     = length(cloudflare_zero_trust_device_default_profile_local_domain_fallback.this) == 0
    error_message = "Without default_profile_local_domain_fallback, the module must not manage the local domain fallback."
  }
}

# Every attribute, global_acceleration included: Cloudflare turns it on
# through sales only, but the mock does not check plans.
run "default_profile" {
  variables {
    default_profile = {
      allow_mode_switch     = true
      allow_updates         = true
      allowed_to_leave      = false
      auto_connect          = 600
      captive_portal        = 300
      disable_auto_fallback = true
      dns_search_suffixes = [
        { suffix = "corp.example", description = "Corporate" },
        { suffix = "example.internal" },
      ]
      exclude_office_ips = true
      global_acceleration = {
        api_endpoints       = ["192.0.2.1:443"]
        enabled             = true
        masque_endpoints    = ["192.0.2.2:443"]
        wireguard_endpoints = ["192.0.2.3:2408"]
      }
      include = [
        { address = "10.0.0.0/8", description = "Private network" },
        { host = "intranet.example" },
      ]
      lan_allow_minutes              = 30
      lan_allow_subnet_size          = 24
      register_interface_ip_with_dns = false
      sccm_vpn_boundary_support      = true
      service_mode_v2                = { mode = "proxy", port = 3128 }
      support_url                    = "https://support.example"
      switch_locked                  = true
      tunnel_protocol                = "wireguard"
      uninstall_protection           = true
      # IDs of virtual networks, from the networks module in practice.
      virtual_networks = {
        allowed = ["f174e90a-fafe-4643-bbbc-4a0ed4fc8415", "a5624d4e-044a-4ff0-b3e1-e2465353d4b4"]
        default = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile.this[0].account_id == var.account_id
    error_message = "The default profile must belong to account_id."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_default_profile.this[0].allow_mode_switch == true &&
      cloudflare_zero_trust_device_default_profile.this[0].allow_updates == true &&
      cloudflare_zero_trust_device_default_profile.this[0].allowed_to_leave == false &&
      cloudflare_zero_trust_device_default_profile.this[0].auto_connect == 600 &&
      cloudflare_zero_trust_device_default_profile.this[0].captive_portal == 300 &&
      cloudflare_zero_trust_device_default_profile.this[0].disable_auto_fallback == true &&
      cloudflare_zero_trust_device_default_profile.this[0].exclude_office_ips == true &&
      cloudflare_zero_trust_device_default_profile.this[0].lan_allow_minutes == 30 &&
      cloudflare_zero_trust_device_default_profile.this[0].lan_allow_subnet_size == 24 &&
      cloudflare_zero_trust_device_default_profile.this[0].register_interface_ip_with_dns == false &&
      cloudflare_zero_trust_device_default_profile.this[0].sccm_vpn_boundary_support == true &&
      cloudflare_zero_trust_device_default_profile.this[0].support_url == "https://support.example" &&
      cloudflare_zero_trust_device_default_profile.this[0].switch_locked == true &&
      cloudflare_zero_trust_device_default_profile.this[0].tunnel_protocol == "wireguard" &&
      cloudflare_zero_trust_device_default_profile.this[0].uninstall_protection == true
    )
    error_message = "Every simple attribute must reach the default profile."
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile.this[0].include == var.default_profile.include
    error_message = "include must reach the default profile."
  }

  # description is computed when left out: the mock fills it.
  assert {
    condition = (
      [for s in cloudflare_zero_trust_device_default_profile.this[0].dns_search_suffixes : s.suffix] == ["corp.example", "example.internal"] &&
      cloudflare_zero_trust_device_default_profile.this[0].dns_search_suffixes[0].description == "Corporate"
    )
    error_message = "dns_search_suffixes must reach the default profile, in order."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_default_profile.this[0].service_mode_v2.mode == "proxy" &&
      cloudflare_zero_trust_device_default_profile.this[0].service_mode_v2.port == 3128
    )
    error_message = "service_mode_v2 must reach the default profile."
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile.this[0].global_acceleration == var.default_profile.global_acceleration
    error_message = "global_acceleration must reach the default profile."
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile.this[0].virtual_networks == var.default_profile.virtual_networks
    error_message = "virtual_networks must reach the default profile."
  }
}

run "default_profile_exclude" {
  command = plan

  variables {
    default_profile = {
      exclude = [
        { address = "192.168.0.0/16" },
        { host = "printer.example", description = "Office printer" },
      ]
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile.this[0].exclude == var.default_profile.exclude
    error_message = "exclude must reach the default profile."
  }
}

run "local_domain_fallback" {
  variables {
    default_profile_local_domain_fallback = {
      domains = [
        { suffix = "corp.example", description = "Corporate", dns_server = ["10.0.0.53", "10.0.1.53"] },
        { suffix = "local" },
      ]
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile_local_domain_fallback.this[0].account_id == var.account_id
    error_message = "The local domain fallback must belong to account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_device_default_profile_local_domain_fallback.this[0].domains == var.default_profile_local_domain_fallback.domains
    error_message = "Every domain must reach the local domain fallback."
  }

  assert {
    condition     = length(cloudflare_zero_trust_device_default_profile.this) == 0
    error_message = "The local domain fallback must not bring the default profile under management."
  }
}
