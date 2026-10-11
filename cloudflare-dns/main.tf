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

  # Cloudflare accepts DNSKEY records only once DNSSEC has
  # `dnssec_multi_signer` on.
  depends_on = [cloudflare_zone_dnssec.this]
}

resource "cloudflare_zone_dns_settings" "this" {
  count = var.dns_settings == null ? 0 : 1

  zone_id             = local.zone.id
  flatten_all_cnames  = var.dns_settings.flatten_all_cnames
  internal_dns        = var.dns_settings.internal_dns
  multi_provider      = var.dns_settings.multi_provider
  nameservers         = var.dns_settings.nameservers
  ns_ttl              = var.dns_settings.ns_ttl
  secondary_overrides = var.dns_settings.secondary_overrides
  soa                 = var.dns_settings.soa
  zone_mode           = var.dns_settings.zone_mode

  lifecycle {
    # Deprecated, so left out of the module. The API still returns it, and
    # without this each plan would set it back to null.
    ignore_changes = [foundation_dns]
  }
}

resource "cloudflare_zone_dnssec" "this" {
  count = var.dnssec == null ? 0 : 1

  zone_id             = local.zone.id
  status              = var.dnssec.status
  dnssec_multi_signer = var.dnssec.dnssec_multi_signer
  dnssec_presigned    = var.dnssec.dnssec_presigned
  dnssec_use_nsec3    = var.dnssec.dnssec_use_nsec3
}
