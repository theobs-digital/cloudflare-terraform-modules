# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "devices" {
  source = "../.."

  account_id = var.account_id

  # Checks that Access and Gateway policies can require of a device.
  device_posture_rules = {
    macos_version = {
      name     = "macOS 15 or later"
      type     = "os_version"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { version = "15.0.0", operator = ">=" }
    }
    disk_encryption = {
      name     = "Disk encryption"
      type     = "disk_encryption"
      schedule = "5m"
      match    = [{ platform = "mac" }, { platform = "windows" }]
      # Every disk; Cloudflare returns [] for no disk in particular.
      input = { require_all = true, check_disks = [] }
    }
  }

  # Devices of the Engineering group take this profile; the others keep the default one.
  device_custom_profiles = {
    engineering = {
      name            = "Engineering"
      match           = "identity.groups.name == \"Engineering\""
      precedence      = 100
      switch_locked   = true
      tunnel_protocol = "masque"
    }
  }
}
