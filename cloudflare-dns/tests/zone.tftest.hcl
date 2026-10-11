mock_provider "cloudflare" {
  mock_resource "cloudflare_zone" {
    defaults = {
      id               = "8ac8489932db6327334c9b6d58544cfe"
      status           = "pending"
      name_servers     = ["ada.ns.cloudflare.com", "bob.ns.cloudflare.com"]
      verification_key = "284344499-1084221259"
    }
  }

  mock_data "cloudflare_zone" {
    defaults = {
      id               = "9f1839b6152d298aca64c4e906b6d074"
      name             = "example.com"
      status           = "active"
      name_servers     = ["carl.ns.cloudflare.com", "dana.ns.cloudflare.com"]
      verification_key = ""
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  name       = "example.com"
}

run "create_zone" {
  variables {
    type                = "partial"
    paused              = true
    vanity_name_servers = ["ns1.example.com", "ns2.example.com"]
  }

  assert {
    condition     = length(cloudflare_zone.this) == 1 && length(data.cloudflare_zone.this) == 0
    error_message = "The module must create the zone, not look it up."
  }

  assert {
    condition     = cloudflare_zone.this[0].account.id == var.account_id && cloudflare_zone.this[0].name == "example.com"
    error_message = "The zone must be created under account_id, with the given name."
  }

  assert {
    condition     = cloudflare_zone.this[0].type == "partial" && cloudflare_zone.this[0].paused == true
    error_message = "type and paused must reach the zone."
  }

  assert {
    condition     = cloudflare_zone.this[0].vanity_name_servers == tolist(["ns1.example.com", "ns2.example.com"])
    error_message = "vanity_name_servers must reach the zone."
  }

  assert {
    condition     = output.zone_id == "8ac8489932db6327334c9b6d58544cfe" && output.name == "example.com" && output.status == "pending"
    error_message = "zone_id, name and status must come from the created zone."
  }

  assert {
    condition     = output.name_servers == tolist(["ada.ns.cloudflare.com", "bob.ns.cloudflare.com"]) && output.verification_key == "284344499-1084221259"
    error_message = "name_servers and verification_key must come from the created zone."
  }
}

# A plan is enough: the data source is read during the plan, so the zone ID is
# known before any apply.
run "adopt_zone" {
  command = plan

  variables {
    create_zone = false
    type        = "partial"
  }

  assert {
    condition     = length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 1
    error_message = "The module must look the zone up, not create it."
  }

  assert {
    condition     = data.cloudflare_zone.this[0].filter.name == "example.com" && data.cloudflare_zone.this[0].filter.account.id == var.account_id
    error_message = "The zone must be looked up by name, in account_id."
  }

  assert {
    condition     = output.zone_id == "9f1839b6152d298aca64c4e906b6d074" && output.name == "example.com" && output.status == "active"
    error_message = "zone_id, name and status must come from the looked-up zone."
  }

  assert {
    condition     = output.name_servers == tolist(["carl.ns.cloudflare.com", "dana.ns.cloudflare.com"])
    error_message = "name_servers must come from the looked-up zone."
  }
}
