mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "custom_profiles_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_custom_profile.this) == 0
    error_message = "Without device_custom_profiles, the module must not manage any custom profile."
  }

  assert {
    condition     = length(cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this) == 0
    error_message = "Without device_custom_profile_local_domain_fallbacks, the module must not manage any local domain fallback."
  }
}

# Every attribute, global_acceleration included: Cloudflare turns it on
# through sales only, but the mock does not check plans.
# Booleans are true: the mock fills a bool left out with false.
run "custom_profiles" {
  variables {
    device_custom_profiles = {
      engineering = {
        name                  = "Engineering"
        allow_mode_switch     = true
        allow_updates         = true
        allowed_to_leave      = true
        auto_connect          = 600
        captive_portal        = 300
        description           = "Engineering laptops"
        disable_auto_fallback = true
        dns_search_suffixes = [
          { suffix = "corp.example", description = "Corporate" },
          { suffix = "example.internal" },
        ]
        enabled            = true
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
        match                          = "identity.email == \"alice@example.com\" or network == \"Office\""
        precedence                     = 101
        profile_type                   = "warp"
        register_interface_ip_with_dns = true
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
      browser = {
        name         = "Browser extension"
        match        = "identity.groups.name == \"Contractors\""
        precedence   = 102
        profile_type = "browser_extension"
        browser_extension_config = {
          proxy_control = "locked"
          proxy_enabled = true
        }
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_custom_profile.this["engineering"].account_id == var.account_id
    error_message = "The custom profiles must belong to account_id."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_custom_profile.this["engineering"].name == "Engineering" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].allow_mode_switch == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].allow_updates == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].allowed_to_leave == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].auto_connect == 600 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].captive_portal == 300 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].description == "Engineering laptops" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].disable_auto_fallback == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].enabled == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].exclude_office_ips == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].lan_allow_minutes == 30 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].lan_allow_subnet_size == 24 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].register_interface_ip_with_dns == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].sccm_vpn_boundary_support == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].support_url == "https://support.example" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].switch_locked == true &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].tunnel_protocol == "wireguard" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].uninstall_protection == true
    )
    error_message = "Every simple attribute must reach the custom profile."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_custom_profile.this["engineering"].match == var.device_custom_profiles["engineering"].match &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].precedence == 101 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].profile_type == "warp"
    )
    error_message = "match, precedence and profile_type must reach the custom profile."
  }

  # address, description and host are computed when left out: the mock fills
  # them.
  assert {
    condition = (
      length(cloudflare_zero_trust_device_custom_profile.this["engineering"].include) == 2 &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].include[0].address == "10.0.0.0/8" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].include[0].description == "Private network" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].include[1].host == "intranet.example"
    )
    error_message = "include must reach the custom profile, in order."
  }

  # description is computed when left out: the mock fills it.
  assert {
    condition = (
      [for s in cloudflare_zero_trust_device_custom_profile.this["engineering"].dns_search_suffixes : s.suffix] == ["corp.example", "example.internal"] &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].dns_search_suffixes[0].description == "Corporate"
    )
    error_message = "dns_search_suffixes must reach the custom profile, in order."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_custom_profile.this["engineering"].service_mode_v2.mode == "proxy" &&
      cloudflare_zero_trust_device_custom_profile.this["engineering"].service_mode_v2.port == 3128
    )
    error_message = "service_mode_v2 must reach the custom profile."
  }

  assert {
    condition     = cloudflare_zero_trust_device_custom_profile.this["engineering"].global_acceleration == var.device_custom_profiles["engineering"].global_acceleration
    error_message = "global_acceleration must reach the custom profile."
  }

  assert {
    condition     = cloudflare_zero_trust_device_custom_profile.this["engineering"].virtual_networks == var.device_custom_profiles["engineering"].virtual_networks
    error_message = "virtual_networks must reach the custom profile."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_custom_profile.this["browser"].profile_type == "browser_extension" &&
      cloudflare_zero_trust_device_custom_profile.this["browser"].browser_extension_config == var.device_custom_profiles["browser"].browser_extension_config
    )
    error_message = "A browser extension profile must get its profile_type and browser_extension_config."
  }

  assert {
    condition = output.device_custom_profile_ids == {
      engineering = cloudflare_zero_trust_device_custom_profile.this["engineering"].id
      browser     = cloudflare_zero_trust_device_custom_profile.this["browser"].id
    }
    error_message = "device_custom_profile_ids must give the ID of each custom profile, by key."
  }
}

run "custom_profile_exclude" {
  variables {
    device_custom_profiles = {
      office = {
        name = "Office"
        exclude = [
          { address = "192.168.0.0/16" },
          { host = "printer.example", description = "Office printer" },
        ]
      }
    }
  }

  assert {
    condition = (
      length(cloudflare_zero_trust_device_custom_profile.this["office"].exclude) == 2 &&
      cloudflare_zero_trust_device_custom_profile.this["office"].exclude[0].address == "192.168.0.0/16" &&
      cloudflare_zero_trust_device_custom_profile.this["office"].exclude[1].host == "printer.example" &&
      cloudflare_zero_trust_device_custom_profile.this["office"].exclude[1].description == "Office printer"
    )
    error_message = "exclude must reach the custom profile, in order."
  }
}

run "fallback_profiles" {
  variables {
    device_custom_profiles = {
      engineering = { name = "Engineering", precedence = 101 }
      sales       = { name = "Sales", precedence = 102 }
    }
  }
}

# policy_id comes from the device_custom_profile_ids output, as a caller writes it.
run "local_domain_fallbacks" {
  variables {
    device_custom_profiles = {
      engineering = { name = "Engineering", precedence = 101 }
      sales       = { name = "Sales", precedence = 102 }
    }
    device_custom_profile_local_domain_fallbacks = {
      engineering = {
        policy_id = run.fallback_profiles.device_custom_profile_ids["engineering"]
        domains = [
          { suffix = "corp.example", description = "Corporate", dns_server = ["10.0.0.53", "10.0.1.53"] },
          { suffix = "local" },
        ]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this["engineering"].account_id == var.account_id &&
      cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this["engineering"].policy_id == cloudflare_zero_trust_device_custom_profile.this["engineering"].id
    )
    error_message = "The local domain fallback must belong to account_id and to the profile its policy_id names."
  }

  assert {
    condition     = cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this["engineering"].domains == var.device_custom_profile_local_domain_fallbacks["engineering"].domains
    error_message = "Every domain must reach the local domain fallback."
  }

  assert {
    condition = output.device_custom_profile_local_domain_fallback_ids == {
      engineering = cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this["engineering"].id
    }
    error_message = "device_custom_profile_local_domain_fallback_ids must give the ID of each local domain fallback, by key."
  }
}
