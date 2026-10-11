mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  name       = "example.com"
}

run "settings_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zone_dns_settings.this) == 0
    error_message = "Without dns_settings, the module must not manage the DNS settings."
  }
}

run "settings" {
  variables {
    dns_settings = {
      flatten_all_cnames  = true
      multi_provider      = true
      nameservers         = { type = "custom.account", nameserver_set_id = "6f5b2c3e8d1a4b7c9e0f2a3b4c5d6e7f" }
      ns_ttl              = 3600
      secondary_overrides = false
      soa = {
        expire  = 604800
        min_ttl = 1800
        mname   = "kristina.ns.cloudflare.com"
        refresh = 10000
        retry   = 2400
        rname   = "admin.example.com"
        ttl     = 3600
      }
      zone_mode = "dns_only"
    }
  }

  assert {
    condition     = cloudflare_zone_dns_settings.this[0].zone_id == output.zone_id
    error_message = "The DNS settings must apply to the zone of the module."
  }

  assert {
    condition = (
      cloudflare_zone_dns_settings.this[0].flatten_all_cnames == true &&
      cloudflare_zone_dns_settings.this[0].multi_provider == true &&
      cloudflare_zone_dns_settings.this[0].ns_ttl == 3600 &&
      cloudflare_zone_dns_settings.this[0].secondary_overrides == false &&
      cloudflare_zone_dns_settings.this[0].zone_mode == "dns_only"
    )
    error_message = "flatten_all_cnames, multi_provider, ns_ttl, secondary_overrides and zone_mode must reach the DNS settings."
  }

  assert {
    condition = (
      cloudflare_zone_dns_settings.this[0].nameservers.type == "custom.account" &&
      cloudflare_zone_dns_settings.this[0].nameservers.nameserver_set_id == "6f5b2c3e8d1a4b7c9e0f2a3b4c5d6e7f"
    )
    error_message = "nameservers must reach the DNS settings."
  }

  assert {
    condition     = cloudflare_zone_dns_settings.this[0].soa == var.dns_settings.soa
    error_message = "Every field of soa must reach the DNS settings."
  }
}

# Internal zones take a reference zone. A plan is enough: the zone is looked
# up, so its ID is known before any apply.
run "internal_zone" {
  command = plan

  variables {
    create_zone = false
    dns_settings = {
      internal_dns = { reference_zone_id = "9f1839b6152d298aca64c4e906b6d074" }
    }
  }

  assert {
    condition     = cloudflare_zone_dns_settings.this[0].zone_id == data.cloudflare_zone.this[0].id
    error_message = "The DNS settings must apply to the looked-up zone."
  }

  assert {
    condition     = cloudflare_zone_dns_settings.this[0].internal_dns.reference_zone_id == "9f1839b6152d298aca64c4e906b6d074"
    error_message = "internal_dns must reach the DNS settings."
  }
}
