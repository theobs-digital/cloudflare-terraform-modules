# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "dns" {
  source = "../.."

  account_id = var.account_id
  name       = "example.com"

  create_zone = true
  type        = "full"
  paused      = false
  # Business and Enterprise plans only.
  vanity_name_servers = ["ns1.example.com", "ns2.example.com"]

  records = {
    apex = {
      name    = "@"
      type    = "A"
      content = "192.0.2.10"
      proxied = true
      comment = "Web server"
    }
    apex6 = { name = "@", type = "AAAA", content = "2001:db8::10", proxied = true }
    www   = { name = "www", type = "CNAME", content = "example.com", proxied = true }
    shop = {
      # Fully qualified, since the record has settings: see Records in the
      # module README.
      name    = "shop.example.com"
      type    = "CNAME"
      content = "shops.example.net"
      ttl     = 3600
      # Paid plans only.
      settings = { flatten_cname = true }
    }
    mx1 = { name = "@", type = "MX", content = "mx1.example.net", priority = 10 }
    mx2 = { name = "@", type = "MX", content = "mx2.example.net", priority = 20 }
    spf = {
      name    = "@"
      type    = "TXT"
      content = "\"v=spf1 mx -all\""
      # Paid plans only.
      tags = ["team:mail"]
    }
    caa = { name = "@", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
    imaps = {
      name     = "_imaps._tcp"
      type     = "SRV"
      priority = 0
      data     = { priority = 0, weight = 0, port = 993, target = "mx1.example.net" }
    }
  }

  # Every simple setting, since the provider reads them all back. These
  # values are the defaults Cloudflare reports for a zone on the Free plan.
  # soa is left out: only Enterprise zones accept it.
  dns_settings = {
    flatten_all_cnames  = false
    multi_provider      = false
    nameservers         = { type = "cloudflare.standard" }
    ns_ttl              = 86400
    secondary_overrides = false
    zone_mode           = "standard"
  }

  # Then give the dnssec output to the registrar.
  dnssec = {
    status              = "active"
    dnssec_multi_signer = false
    dnssec_presigned    = false
    dnssec_use_nsec3    = false
  }
}
