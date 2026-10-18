# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

locals {
  # The objects as they are in Cloudflare, under keys of your choice.

  # The default profile of an organization on the Free plan, as Cloudflare
  # created it. Write each value the plan shows changing.
  default_profile = {
    tunnel_protocol = "masque"
    service_mode_v2 = { mode = "warp" }
    exclude = [
      { address = "10.0.0.0/8" },
      { address = "100.64.0.0/10" },
      { address = "169.254.0.0/16", description = "DHCP Unspecified" },
      { address = "172.16.0.0/12" },
      { address = "192.0.0.0/24" },
      { address = "192.168.0.0/16" },
      { address = "224.0.0.0/24" },
      { address = "240.0.0.0/4" },
      { address = "255.255.255.255/32", description = "DHCP Broadcast" },
      { address = "fe80::/10", description = "IPv6 Link Local" },
      { address = "fd00::/8" },
      { address = "ff01::/16" },
      { address = "ff02::/16" },
      { address = "ff03::/16" },
      { address = "ff04::/16" },
      { address = "ff05::/16" },
    ]
  }

  default_profile_local_domain_fallback = {
    domains = [for suffix in [
      "home.arpa", "intranet", "internal", "private", "localdomain", "domain", "lan",
      "home", "host", "corp", "local", "localhost", "invalid", "test",
    ] : { suffix = suffix }]
  }

  custom_profiles = {
    engineering = {
      name       = "Engineering"
      match      = "identity.groups.name == \"Engineering\""
      precedence = 100
    }
  }

  # Under the key of their profile.
  custom_profile_local_domain_fallbacks = {
    engineering = {
      domains = [{ suffix = "corp.example.com", dns_server = ["10.0.0.53"] }]
    }
  }

  managed_networks = {
    office = { name = "Office", type = "tls", config = { tls_sockaddr = "10.1.0.10:443" } }
  }

  posture_rules = {
    # Cloudflare sets schedule to 5m when it is left out: write it.
    macos_version = {
      name     = "macOS 15 or later"
      type     = "os_version"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { version = "15.0.0", operator = ">=" }
    }
  }

  # Imported by ID, from var.subnet_ids. Write comment and is_default_network
  # as Cloudflare holds them.
  subnets = {
    engineering = { name = "Engineering", network = "10.80.0.0/16", comment = "", is_default_network = false }
  }

  # With the key of their subnet.
  ip_profiles = {
    engineering = {
      name       = "Engineering"
      match      = "identity.groups.name == \"Engineering\""
      precedence = 100
      subnet     = "engineering"
    }
  }

  # Imported by ID, from var.deployment_group_ids. With the keys of their
  # custom profiles, or default for the default profile.
  deployment_groups = {
    ring0 = {
      name           = "Ring 0"
      version_config = [{ target_environment = "windows", version = "2026.8.2110.0" }]
      profiles       = ["engineering"]
    }
  }
}

module "devices" {
  source = "../.."

  account_id = var.account_id

  device_default_profile                       = local.default_profile
  device_default_profile_local_domain_fallback = local.default_profile_local_domain_fallback
  device_custom_profiles                       = local.custom_profiles
  device_managed_networks                      = local.managed_networks
  device_posture_rules                         = local.posture_rules
  device_subnets                               = local.subnets

  # The IDs come from the module's outputs. The type of each input drops the
  # subnet and profiles keys.
  device_custom_profile_local_domain_fallbacks = {
    for key, fallback in local.custom_profile_local_domain_fallbacks :
    key => merge(fallback, { policy_id = module.devices.device_custom_profile_ids[key] })
  }

  device_ip_profiles = {
    for key, profile in local.ip_profiles :
    key => merge(profile, { subnet_id = module.devices.device_subnet_ids[profile.subnet] })
  }

  device_deployment_groups = {
    for key, group in local.deployment_groups : key => merge(group, {
      policy_ids = [
        for profile in group.profiles :
        merge(module.devices.device_custom_profile_ids, { default = module.devices.device_default_profile_policy_id })[profile]
      ]
    })
  }
}

data "cloudflare_zero_trust_device_custom_profiles" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_device_managed_networks_list" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_device_posture_rules" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_device_ip_profiles" "existing" {
  account_id = var.account_id
}

# The existing object each entry stands for: the same name. one() fails on two
# matches. One local per kind, or Terraform reports a cycle when one kind
# refers to another.
locals {
  existing_custom_profile_ids = {
    for key, profile in local.custom_profiles : key => one([
      for existing in data.cloudflare_zero_trust_device_custom_profiles.existing.result : existing.policy_id
      if existing.name == profile.name
    ])
  }

  existing_managed_network_ids = {
    for key, network in local.managed_networks : key => one([
      for existing in data.cloudflare_zero_trust_device_managed_networks_list.existing.result : existing.network_id
      if existing.name == network.name
    ])
  }

  existing_posture_rule_ids = {
    for key, rule in local.posture_rules : key => one([
      for existing in data.cloudflare_zero_trust_device_posture_rules.existing.result : existing.id
      if existing.name == rule.name
    ])
  }

  existing_ip_profile_ids = {
    for key, profile in local.ip_profiles : key => one([
      for existing in data.cloudflare_zero_trust_device_ip_profiles.existing.result : existing.id
      if existing.name == profile.name
    ])
  }
}

# The default profile and its local domain fallback always exist: their ID is
# the account ID.
import {
  to = module.devices.cloudflare_zero_trust_device_default_profile.this[0]
  id = var.account_id
}

import {
  to = module.devices.cloudflare_zero_trust_device_default_profile_local_domain_fallback.this[0]
  id = var.account_id
}

# An entry that matches no existing object is not imported: the plan creates
# it, and the unmatched output lists it.
import {
  for_each = { for key, id in local.existing_custom_profile_ids : key => id if id != null }
  to       = module.devices.cloudflare_zero_trust_device_custom_profile.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

# A local domain fallback's ID is its profile's.
import {
  for_each = {
    for key in keys(local.custom_profile_local_domain_fallbacks) : key => local.existing_custom_profile_ids[key]
    if local.existing_custom_profile_ids[key] != null
  }
  to = module.devices.cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this[each.key]
  id = "${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_managed_network_ids : key => id if id != null }
  to       = module.devices.cloudflare_zero_trust_device_managed_networks.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_posture_rule_ids : key => id if id != null }
  to       = module.devices.cloudflare_zero_trust_device_posture_rule.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

# By ID: the provider has no data source that lists subnets.
import {
  for_each = var.subnet_ids
  to       = module.devices.cloudflare_zero_trust_device_subnet.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_ip_profile_ids : key => id if id != null }
  to       = module.devices.cloudflare_zero_trust_device_ip_profile.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

# By ID: in provider 5.28.0, the data source that lists them reads the same
# page again and again, up to max_items.
import {
  for_each = var.deployment_group_ids
  to       = module.devices.cloudflare_zero_trust_device_deployment_groups.this[each.key]
  id       = "${var.account_id}/${each.value}"
}
