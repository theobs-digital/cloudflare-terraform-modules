# Real API, not a mock: apply this configuration, plan it again, which must
# show no change, and destroy it. Every object is named tf-test-ci-*, the
# subnet takes 10.253.0.0/24, and the objects of the whole account are left
# alone: device settings, the default profile and its local domain fallback,
# device certificates. Posture integrations need a third-party service.
#
#   export CLOUDFLARE_API_TOKEN=...
#   terraform init
#   terraform apply -var account_id=...
#   terraform plan -detailed-exitcode -var account_id=...
#   terraform destroy -var account_id=...
provider "cloudflare" {}

# Cloudflare also creates a serial_number posture rule of the same name, which
# goes with the list.
resource "cloudflare_zero_trust_list" "serials" {
  account_id = var.account_id
  name       = "tf-test-ci-serials"
  type       = "SERIAL"
  items      = [{ value = "TFTESTCI0001" }]
}

module "devices" {
  source = "../"

  account_id = var.account_id

  device_managed_networks = {
    office = { name = "tf-test-ci-office", type = "tls", config = { tls_sockaddr = "192.0.2.20:443" } }
  }

  device_custom_profiles = {
    office = {
      name            = "tf-test-ci-office"
      match           = "network == \"tf-test-ci-office\""
      precedence      = 9301
      service_mode_v2 = { mode = "proxy", port = 3128 }
    }
    # Every attribute the Free plan accepts, with values other than the defaults.
    engineering = {
      name                           = "tf-test-ci-engineering"
      description                    = "tf-test-ci"
      match                          = "identity.email == \"engineering@tf-test-ci.example\""
      precedence                     = 9302
      enabled                        = true
      allow_mode_switch              = true
      allow_updates                  = true
      allowed_to_leave               = false
      auto_connect                   = 900
      captive_portal                 = 300
      disable_auto_fallback          = true
      dns_search_suffixes            = [{ suffix = "corp.tf-test-ci.example", description = "tf-test-ci" }]
      exclude_office_ips             = true
      include                        = [{ address = "10.253.0.0/16", description = "tf-test-ci" }, { host = "intranet.tf-test-ci.example" }]
      lan_allow_minutes              = 30
      lan_allow_subnet_size          = 24
      register_interface_ip_with_dns = false
      sccm_vpn_boundary_support      = true
      service_mode_v2                = { mode = "warp" }
      support_url                    = "https://tf-test-ci.example/support"
      switch_locked                  = true
      tunnel_protocol                = "masque"
      uninstall_protection           = true
    }
  }

  device_custom_profile_local_domain_fallbacks = {
    engineering = {
      policy_id = module.devices.device_custom_profile_ids["engineering"]
      domains = [
        { suffix = "corp.tf-test-ci.example", description = "tf-test-ci", dns_server = ["192.0.2.53"] },
        { suffix = "local" },
      ]
    }
  }

  device_posture_rules = {
    os_version_mac = {
      name     = "tf-test-ci-os-version-mac"
      type     = "os_version"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { version = "15.0.0", operator = ">=" }
    }
    os_version_linux = {
      name        = "tf-test-ci-os-version-linux"
      description = "tf-test-ci"
      type        = "os_version"
      schedule    = "5m"
      expiration  = "1h"
      match       = [{ platform = "linux" }]
      input       = { version = "6.8.0", operator = ">=", os_distro_name = "ubuntu", os_distro_revision = "24.04" }
    }
    firewall_windows = {
      name     = "tf-test-ci-firewall-windows"
      type     = "firewall"
      schedule = "10m"
      match    = [{ platform = "windows" }]
      input    = { enabled = true }
    }
    disk_encryption = {
      name     = "tf-test-ci-disk-encryption"
      type     = "disk_encryption"
      schedule = "5m"
      match    = [{ platform = "mac" }, { platform = "windows" }]
      input    = { require_all = true, check_disks = [] }
    }
    file_windows = {
      name     = "tf-test-ci-file-windows"
      type     = "file"
      schedule = "5m"
      match    = [{ platform = "windows" }]
      input = {
        path   = "C:\\Program Files\\Example\\example.exe"
        exists = true
        sha256 = "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
      }
    }
    application_mac = {
      name     = "tf-test-ci-application-mac"
      type     = "application"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { path = "/Applications/Example.app" }
    }
    domain_joined_windows = {
      name     = "tf-test-ci-domain-joined-windows"
      type     = "domain_joined"
      schedule = "5m"
      match    = [{ platform = "windows" }]
      input    = { domain = "corp.tf-test-ci.example" }
    }
    warp = {
      name = "tf-test-ci-warp"
      type = "warp"
    }
    gateway = {
      name = "tf-test-ci-gateway"
      type = "gateway"
    }
    serial_number = {
      name     = "tf-test-ci-serial-number"
      type     = "serial_number"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { id = cloudflare_zero_trust_list.serials.id }
    }
  }

  device_subnets = {
    engineering = { name = "tf-test-ci-engineering", network = "10.253.0.0/24", comment = "tf-test-ci" }
  }

  device_ip_profiles = {
    engineering = {
      name        = "tf-test-ci-engineering"
      description = "tf-test-ci"
      match       = "identity.email == \"engineering@tf-test-ci.example\""
      precedence  = 9301
      subnet_id   = module.devices.device_subnet_ids["engineering"]
    }
  }

  # No device is enrolled in the test organization: no client takes these versions.
  device_deployment_groups = {
    ring0 = {
      name = "tf-test-ci-ring0"
      version_config = [
        { target_environment = "windows", version = "2026.8.2110.0" },
        { target_environment = "macos", version = "2026.8.2110.0" },
      ]
      policy_ids = [module.devices.device_custom_profile_ids["engineering"]]
    }
    ring1 = {
      name           = "tf-test-ci-ring1"
      version_config = [{ target_environment = "macos", version = "2026.8.2100.0" }]
      policy_ids     = [module.devices.device_custom_profile_ids["office"]]
    }
  }
}
