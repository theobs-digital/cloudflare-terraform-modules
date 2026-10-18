# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

locals {
  # Custom profiles match a managed network by its name, which Cloudflare does not check.
  office_network = "Office"
}

module "devices" {
  source = "../.."

  account_id = var.account_id

  # Settings of the whole account. Write every field Cloudflare returns: see the README.
  device_settings = {
    disable_for_time                      = 0
    gateway_proxy_enabled                 = true
    gateway_udp_proxy_enabled             = true
    root_certificate_installation_enabled = false
    use_zt_virtual_ip                     = true
  }

  # The profile of every device no custom profile matches. Import it first: see the README.
  device_default_profile = {
    tunnel_protocol = "masque"
    service_mode_v2 = { mode = "warp" }
    support_url     = "https://help.example.com/vpn"
    # Private ranges go through Cloudflare, to the networks behind tunnels; home networks stay local.
    exclude = [
      { address = "192.168.0.0/16", description = "Home networks" },
      { address = "169.254.0.0/16", description = "DHCP Unspecified" },
      { address = "fe80::/10", description = "IPv6 Link Local" },
    ]
  }

  # Replaces the whole list: the domains Cloudflare recommends are written back.
  device_default_profile_local_domain_fallback = {
    domains = concat(
      [{ suffix = "corp.example.com", description = "Internal zone", dns_server = ["10.0.0.53"] }],
      [for suffix in [
        "home.arpa", "intranet", "internal", "private", "localdomain", "domain", "lan",
        "home", "host", "corp", "local", "localhost", "invalid", "test",
      ] : { suffix = suffix }],
    )
  }

  # The client certificate WARP installs, for mTLS on this zone.
  device_default_profile_certificates = {
    example = { zone_id = var.zone_id, enabled = true }
  }

  device_managed_networks = {
    office = {
      name = local.office_network
      type = "tls"
      # A host the office network alone reaches, and the SHA-256 fingerprint of its certificate.
      config = {
        tls_sockaddr = "10.1.0.10:443"
        sha256       = "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
      }
    }
  }

  # The first profile whose match is true, in increasing precedence; gaps leave room.
  device_custom_profiles = {
    office = {
      name       = "Office"
      match      = "network == \"${local.office_network}\""
      precedence = 100
      exclude    = [{ address = "10.1.0.0/16", description = "Office LAN, reached directly" }]
    }
    engineering = {
      name                  = "Engineering"
      description           = "Engineers, away from the office"
      match                 = "identity.groups.name == \"Engineering\""
      precedence            = 200
      tunnel_protocol       = "masque"
      switch_locked         = true
      dns_search_suffixes   = [{ suffix = "corp.example.com" }]
      lan_allow_minutes     = 30
      lan_allow_subnet_size = 24
    }
  }

  # Under the key of their profile, whose ID they take.
  device_custom_profile_local_domain_fallbacks = {
    engineering = {
      policy_id = module.devices.device_custom_profile_ids["engineering"]
      domains = [
        { suffix = "lab.example.com", description = "Lab zone", dns_server = ["10.2.0.53"] },
        { suffix = "local" },
      ]
    }
  }

  # Cloudflare calls api_url with the service token to create it: the service must answer.
  device_posture_integrations = {
    posture_service = {
      name     = "Posture service"
      type     = "custom_s2s"
      interval = "10m"
      config = {
        api_url              = "https://posture.example.com/devices"
        access_client_id     = var.posture_service_client_id
        access_client_secret = var.posture_service_client_secret
      }
    }
  }

  # Write schedule: an imported rule plans a change without it.
  device_posture_rules = {
    macos_version = {
      name     = "macOS 15 or later"
      type     = "os_version"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { version = "15.0.0", operator = ">=" }
    }
    windows_firewall = {
      name     = "Windows firewall on"
      type     = "firewall"
      schedule = "5m"
      match    = [{ platform = "windows" }]
      input    = { enabled = true }
    }
    disk_encryption = {
      name     = "Disk encryption"
      type     = "disk_encryption"
      schedule = "5m"
      match    = [{ platform = "mac" }, { platform = "windows" }]
      input    = { require_all = true, check_disks = [] }
    }
    # A serial number listed in a Gateway list of type SERIAL.
    corporate_device = {
      name     = "Corporate device"
      type     = "serial_number"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { id = var.serial_number_list_id }
    }
    # A certificate issued by the company CA, whose CN is the serial number of the device.
    client_certificate = {
      name     = "Client certificate"
      type     = "client_certificate_v2"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input = {
        certificate_id    = var.client_ca_certificate_id
        cn                = "$${serial_number}" # $$: a variable of the client, not of Terraform
        check_private_key = true
        locations         = { trust_stores = ["system"] }
      }
    }
    posture_score = {
      name     = "Posture score of 70 or more"
      type     = "custom_s2s"
      schedule = "5m"
      input = {
        connection_id = module.devices.device_posture_integration_ids["posture_service"]
        score         = 70
        operator      = ">="
      }
    }
  }

  device_subnets = {
    engineering = { name = "Engineering", network = "10.80.0.0/16", comment = "Devices of the Engineering group" }
  }

  device_ip_profiles = {
    engineering = {
      name        = "Engineering"
      description = "Engineers take their IP from 10.80.0.0/16"
      match       = "identity.groups.name == \"Engineering\""
      precedence  = 100
      subnet_id   = module.devices.device_subnet_ids["engineering"]
    }
  }

  # Engineers take a release first; the other profiles, the default one included, follow.
  device_deployment_groups = {
    ring0 = {
      name = "Ring 0"
      version_config = [
        { target_environment = "windows", version = var.client_versions.ring0 },
        { target_environment = "macos", version = var.client_versions.ring0 },
      ]
      policy_ids = [module.devices.device_custom_profile_ids["engineering"]]
    }
    ring1 = {
      name = "Ring 1"
      version_config = [
        { target_environment = "windows", version = var.client_versions.ring1 },
        { target_environment = "macos", version = var.client_versions.ring1 },
      ]
      policy_ids = [
        module.devices.device_default_profile_policy_id,
        module.devices.device_custom_profile_ids["office"],
      ]
    }
  }
}
