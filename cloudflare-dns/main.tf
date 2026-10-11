resource "cloudflare_zone" "this" {
  count = var.create_zone ? 1 : 0

  account = {
    id = var.account_id
  }
  name                = var.name
  type                = var.type
  paused              = var.paused
  vanity_name_servers = var.vanity_name_servers
}

# Adoption mode: another configuration owns the zone, the module only looks it
# up.
data "cloudflare_zone" "this" {
  count = var.create_zone ? 0 : 1

  filter = {
    account = {
      id = var.account_id
    }
    name = var.name
  }
}

locals {
  # The zone, whether the module created it or looked it up. Only the
  # attributes the module uses: the whole object holds deprecated ones, which
  # would raise a warning at each plan.
  zone = one([
    for zone in concat(cloudflare_zone.this, data.cloudflare_zone.this) : {
      id               = zone.id
      name             = zone.name
      status           = zone.status
      name_servers     = zone.name_servers
      verification_key = zone.verification_key
    }
  ])
}

resource "cloudflare_dns_record" "this" {
  for_each = var.records

  zone_id         = local.zone.id
  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.ttl
  content         = each.value.content
  data            = each.value.data
  proxied         = each.value.proxied
  priority        = each.value.priority
  comment         = each.value.comment
  tags            = each.value.tags
  settings        = each.value.settings
  private_routing = each.value.private_routing

  # Only asks the API to fill the computed `meta` attribute.
  include_shadow_metadata = each.value.include_shadow_metadata
}
