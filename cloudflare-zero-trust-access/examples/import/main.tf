# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

locals {
  # The objects as they are in Cloudflare, under keys of your choice.
  identity_providers = {
    # Set up from the dashboard, a one-time PIN can have an empty name.
    otp = { name = "", type = "onetimepin", config = {} }
  }

  groups = {
    staff = { name = "Staff", include = [{ email_domain = { domain = "example.com" } }] }
  }

  policies = {
    staff = {
      name     = "Staff"
      decision = "allow"
      include  = [{ group = { id = module.access.access_group_ids["staff"] } }]
      # Set by the dashboard.
      session_duration = "24h"
    }
  }

  applications = {
    wiki = {
      name         = "Wiki"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "wiki.example.com" }]
      policies     = [{ id = module.access.access_policy_ids["staff"], precedence = 1 }]
      # Cloudflare returns them as false: left out, the plan sets them to null.
      auto_redirect_to_identity = false
      enable_binding_cookie     = false
      options_preflight_bypass  = false
    }
  }
}

module "access" {
  source = "../.."

  account_id = var.account_id

  # An organization left at its defaults.
  organization = {
    name                                        = "example.cloudflareaccess.com"
    auth_domain                                 = "example.cloudflareaccess.com"
    deny_unmatched_requests                     = false
    deny_unmatched_requests_exempted_zone_names = []
  }

  access_identity_providers = local.identity_providers
  access_groups             = local.groups
  access_policies           = local.policies
  access_applications       = local.applications
}

data "cloudflare_zero_trust_access_identity_providers" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_access_groups" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_access_policies" "existing" {
  account_id = var.account_id
}

data "cloudflare_zero_trust_access_applications" "existing" {
  account_id = var.account_id
}

# The existing object each entry stands for: the same name, and the same type
# for identity providers and applications. one() fails on two matches. One
# local per kind, or Terraform reports a cycle: applications refer to
# policies, which refer to groups.
locals {
  existing_identity_provider_ids = {
    for key, idp in local.identity_providers : key => one([
      for existing in data.cloudflare_zero_trust_access_identity_providers.existing.result : existing.id
      if existing.name == idp.name && existing.type == idp.type
    ])
  }

  existing_group_ids = {
    for key, group in local.groups : key => one([
      for existing in data.cloudflare_zero_trust_access_groups.existing.result : existing.id
      if existing.name == group.name
    ])
  }

  existing_policy_ids = {
    for key, policy in local.policies : key => one([
      for existing in data.cloudflare_zero_trust_access_policies.existing.result : existing.id
      if existing.name == policy.name
    ])
  }

  existing_application_ids = {
    for key, app in local.applications : key => one([
      for existing in data.cloudflare_zero_trust_access_applications.existing.result : existing.id
      if existing.name == app.name && existing.type == app.type
    ])
  }
}

import {
  to = module.access.cloudflare_zero_trust_organization.this[0]
  id = var.account_id
}

# An entry that matches no existing object is not imported: the plan creates
# it, and the unmatched output lists it.
import {
  for_each = { for key, id in local.existing_identity_provider_ids : key => id if id != null }
  to       = module.access.cloudflare_zero_trust_access_identity_provider.this[each.key]
  id       = "accounts/${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_group_ids : key => id if id != null }
  to       = module.access.cloudflare_zero_trust_access_group.this[each.key]
  id       = "accounts/${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_policy_ids : key => id if id != null }
  to       = module.access.cloudflare_zero_trust_access_policy.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

import {
  for_each = { for key, id in local.existing_application_ids : key => id if id != null }
  to       = module.access.cloudflare_zero_trust_access_application.this[each.key]
  id       = "accounts/${var.account_id}/${each.value}"
}
