mock_provider "cloudflare" {
  mock_resource "cloudflare_zone" {
    defaults = {
      id = "8ac8489932db6327334c9b6d58544cfe"
    }
  }

  mock_resource "cloudflare_dns_record" {
    defaults = {
      id = "023e105f4ecef8ad9ca31a8372d0c353"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  name       = "example.com"
}

run "no_records" {
  command = plan

  assert {
    condition     = length(cloudflare_dns_record.this) == 0
    error_message = "Without records, the module must not create any."
  }
}

run "content_records" {
  variables {
    records = {
      apex = { name = "@", type = "A", content = "192.0.2.10", proxied = true }
      www = {
        name            = "www"
        type            = "CNAME"
        content         = "example.com"
        ttl             = 3600
        comment         = "Main site"
        tags            = ["team:web"]
        settings        = { flatten_cname = true }
        private_routing = false

        include_shadow_metadata = true
      }
      mx = { name = "@", type = "MX", content = "mx1.example.net", priority = 10 }
    }
  }

  assert {
    condition     = alltrue([for record in cloudflare_dns_record.this : record.zone_id == "8ac8489932db6327334c9b6d58544cfe"])
    error_message = "Every record must belong to the zone."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].name == "@" && cloudflare_dns_record.this["apex"].type == "A" && cloudflare_dns_record.this["apex"].content == "192.0.2.10"
    error_message = "name, type and content must reach the record as given."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].proxied == true && cloudflare_dns_record.this["apex"].ttl == 1
    error_message = "proxied must reach the record, and ttl must default to 1."
  }

  assert {
    condition     = cloudflare_dns_record.this["www"].ttl == 3600 && cloudflare_dns_record.this["www"].comment == "Main site" && cloudflare_dns_record.this["www"].tags == toset(["team:web"])
    error_message = "ttl, comment and tags must reach the record."
  }

  assert {
    condition     = cloudflare_dns_record.this["www"].settings.flatten_cname == true && cloudflare_dns_record.this["www"].private_routing == false
    error_message = "settings and private_routing must reach the record."
  }

  assert {
    condition     = cloudflare_dns_record.this["www"].include_shadow_metadata == true
    error_message = "include_shadow_metadata must reach the record."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx"].priority == 10 && cloudflare_dns_record.this["mx"].data == null
    error_message = "priority must reach the record, and data must stay unset."
  }

  assert {
    condition = output.record_ids == {
      apex = "023e105f4ecef8ad9ca31a8372d0c353"
      mx   = "023e105f4ecef8ad9ca31a8372d0c353"
      www  = "023e105f4ecef8ad9ca31a8372d0c353"
    }
    error_message = "record_ids must give the ID of each record, by key."
  }
}

# Flags hold a number in CAA and DNSKEY records, a string in NAPTR records.
# Next to a NAPTR record, Terraform turns the CAA flags into "0": Cloudflare
# stores it as 0, without any change at the next plan (checked on a real zone).
run "data_records" {
  variables {
    records = {
      caa = { name = "@", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
      sip = { name = "_sip._udp", type = "SRV", data = { priority = 10, weight = 5, port = 5060, target = "sip.example.com" } }
      naptr = {
        name = "sip"
        type = "NAPTR"
        data = { order = 100, preference = 10, flags = "S", service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.com." }
      }
    }
  }

  assert {
    condition     = tonumber(cloudflare_dns_record.this["caa"].data.flags) == 0 && cloudflare_dns_record.this["caa"].data.tag == "issue" && cloudflare_dns_record.this["caa"].data.value == "letsencrypt.org"
    error_message = "The CAA data must reach the record."
  }

  assert {
    condition     = cloudflare_dns_record.this["naptr"].data.flags == "S" && cloudflare_dns_record.this["naptr"].data.replacement == "_sip._udp.example.com."
    error_message = "The NAPTR data must reach the record, with text flags."
  }

  assert {
    condition     = cloudflare_dns_record.this["sip"].data.priority == 10 && cloudflare_dns_record.this["sip"].data.port == 5060 && cloudflare_dns_record.this["sip"].data.flags == null
    error_message = "The SRV data must reach the record, without flags."
  }
}

# The provider lets both mistakes through the plan.
run "record_without_value" {
  command = plan

  variables {
    records = {
      apex = { name = "@", type = "A" }
    }
  }

  expect_failures = [var.records]
}

run "proxied_record_with_ttl" {
  command = plan

  variables {
    records = {
      apex = { name = "@", type = "A", content = "192.0.2.10", proxied = true, ttl = 300 }
    }
  }

  expect_failures = [var.records]
}
