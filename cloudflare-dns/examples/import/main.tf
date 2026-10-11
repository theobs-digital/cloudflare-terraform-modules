# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

locals {
  name = "example.com"

  # The records as they are in Cloudflare. For a large zone,
  # `cf-terraforming generate` writes them out.
  records = {
    apex  = { name = "@", type = "A", content = "192.0.2.10", proxied = true }
    www   = { name = "www", type = "CNAME", content = "example.com", proxied = true }
    mx1   = { name = "@", type = "MX", content = "mx1.example.net", priority = 10 }
    mx2   = { name = "@", type = "MX", content = "mx2.example.net", priority = 20 }
    spf   = { name = "@", type = "TXT", content = "\"v=spf1 mx -all\"" }
    caa   = { name = "@", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
    imaps = { name = "_imaps._tcp", type = "SRV", priority = 0, data = { priority = 0, weight = 0, port = 993, target = "mx1.example.net" } }
  }
}

module "dns" {
  source = "../.."

  account_id = var.account_id
  name       = local.name
  records    = local.records
}

data "cloudflare_zone" "existing" {
  filter = {
    account = { id = var.account_id }
    name    = local.name
  }
}

# One read per record type. Read together, a record with data.flags (CAA,
# NAPTR...) and one of another type crash Terraform with "inconsistent list
# element types" (provider issue #7004).
data "cloudflare_dns_records" "existing" {
  for_each = toset([for record in local.records : record.type])

  zone_id = data.cloudflare_zone.existing.id
  type    = each.key
  # The data source reads 1000 records unless told otherwise.
  max_items = 5000
}

locals {
  # The API returns fully qualified names.
  fqdn = {
    for key, record in local.records : key => (
      record.name == "@" ? local.name :
      record.name == local.name || endswith(record.name, ".${local.name}") ? record.name :
      "${record.name}.${local.name}"
    )
  }

  # The existing record each entry stands for: same type and name, and same
  # content, or for a record with data, the same value in each field of data
  # the entry sets.
  existing_ids = {
    for key, record in local.records : key => one([
      for existing in data.cloudflare_dns_records.existing[record.type].result : existing.id
      if existing.name == local.fqdn[key] && (
        can(record.content)
        ? existing.content == record.content
        : alltrue([for field, value in record.data : try(existing.data[field] == value, false)])
      )
    ])
  }
}

import {
  to = module.dns.cloudflare_zone.this[0]
  id = data.cloudflare_zone.existing.id
}

# An entry that matches no existing record is not imported: the plan creates
# it, and the unmatched_records output lists it.
import {
  for_each = { for key, id in local.existing_ids : key => id if id != null }
  to       = module.dns.cloudflare_dns_record.this[each.key]
  id       = "${data.cloudflare_zone.existing.id}/${each.value}"
}
