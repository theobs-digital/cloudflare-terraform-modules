# Real API, not a mock: records under tf-test.<zone> only, created then
# destroyed. The zone must exist, and the module never changes it.
#
#   export CLOUDFLARE_API_TOKEN=...
#   terraform test -test-directory=tests-real -var name=example.com -var account_id=...
provider "cloudflare" {}

variables {
  create_zone = false

  # Values as Cloudflare stores them, see Records in the README: a value it
  # rewrites fails the plans below.
  records = {
    a     = { name = "a.tf-test", type = "A", content = "192.0.2.10" }
    aaaa  = { name = "aaaa.tf-test", type = "AAAA", content = "2001:db8::10", ttl = 300 }
    cname = { name = "cname.tf-test", type = "CNAME", content = "example.net" }
    mx    = { name = "mx.tf-test", type = "MX", content = "mx1.example.net", priority = 10 }
    txt   = { name = "txt.tf-test", type = "TXT", content = "tf-test" }
    srv   = { name = "_sip._tcp.tf-test", type = "SRV", priority = 10, data = { priority = 10, weight = 5, port = 5060, target = "sip.example.net" } }
    caa   = { name = "caa.tf-test", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
    naptr = { name = "naptr.tf-test", type = "NAPTR", data = { order = 100, preference = 10, flags = "S", service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.net." } }
    sshfp = { name = "sshfp.tf-test", type = "SSHFP", data = { algorithm = 4, type = 2, fingerprint = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" } }
    tlsa  = { name = "_443._tcp.tlsa.tf-test", type = "TLSA", data = { usage = 3, selector = 1, matching_type = 1, certificate = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" } }
    https = { name = "https.tf-test", type = "HTTPS", data = { priority = 1, target = ".", value = "alpn=\"h2\"" } }
    svcb  = { name = "_dns.svcb.tf-test", type = "SVCB", data = { priority = 1, target = "dns.example.net.", value = "alpn=\"dot\"" } }
    uri   = { name = "_http._tcp.uri.tf-test", type = "URI", priority = 10, data = { weight = 1, target = "https://example.net/" } }
    loc   = { name = "loc.tf-test", type = "LOC", data = { lat_degrees = 48, lat_minutes = 51, lat_seconds = 24, lat_direction = "N", long_degrees = 2, long_minutes = 21, long_seconds = 7, long_direction = "E", altitude = 35, size = 1, precision_horz = 10000, precision_vert = 10 } }
  }
}

run "create" {
  assert {
    condition     = length(output.record_ids) == 14
    error_message = "Every record must be created."
  }
}

# The provider keeps modified_on, and id, known only when it plans no change.
run "no_drift" {
  command = plan

  assert {
    condition     = alltrue([for record in cloudflare_dns_record.this : record.id != null && record.modified_on != null])
    error_message = "A second plan must leave every record unchanged."
  }
}

run "update" {
  variables {
    records = {
      a     = { name = "a.tf-test", type = "A", content = "192.0.2.11" }
      aaaa  = { name = "aaaa.tf-test", type = "AAAA", content = "2001:db8::10", ttl = 3600 }
      cname = { name = "cname.tf-test", type = "CNAME", content = "example.net", comment = "tf-test" }
      mx    = { name = "mx.tf-test", type = "MX", content = "mx1.example.net", priority = 20 }
      txt   = { name = "txt.tf-test", type = "TXT", content = "tf-test-v2" }
      srv   = { name = "_sip._tcp.tf-test", type = "SRV", priority = 10, data = { priority = 10, weight = 5, port = 5061, target = "sip.example.net" } }
      caa   = { name = "caa.tf-test", type = "CAA", data = { flags = 0, tag = "issue", value = "pki.goog" } }
      naptr = { name = "naptr.tf-test", type = "NAPTR", data = { order = 100, preference = 20, flags = "S", service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.net." } }
      sshfp = { name = "sshfp.tf-test", type = "SSHFP", data = { algorithm = 4, type = 2, fingerprint = "FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210" } }
      tlsa  = { name = "_443._tcp.tlsa.tf-test", type = "TLSA", data = { usage = 3, selector = 1, matching_type = 1, certificate = "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210" } }
      https = { name = "https.tf-test", type = "HTTPS", data = { priority = 1, target = ".", value = "alpn=\"h3\"" } }
      svcb  = { name = "_dns.svcb.tf-test", type = "SVCB", data = { priority = 2, target = "dns.example.net.", value = "alpn=\"dot\"" } }
      uri   = { name = "_http._tcp.uri.tf-test", type = "URI", priority = 20, data = { weight = 1, target = "https://example.net/" } }
      loc   = { name = "loc.tf-test", type = "LOC", data = { lat_degrees = 48, lat_minutes = 51, lat_seconds = 24, lat_direction = "N", long_degrees = 2, long_minutes = 21, long_seconds = 7, long_direction = "E", altitude = 40, size = 1, precision_horz = 10000, precision_vert = 10 } }
    }
  }

  assert {
    condition     = output.record_ids == run.create.record_ids
    error_message = "Each change must update the record in place, under the same ID."
  }
}

run "no_drift_after_update" {
  command = plan

  variables {
    records = {
      a     = { name = "a.tf-test", type = "A", content = "192.0.2.11" }
      aaaa  = { name = "aaaa.tf-test", type = "AAAA", content = "2001:db8::10", ttl = 3600 }
      cname = { name = "cname.tf-test", type = "CNAME", content = "example.net", comment = "tf-test" }
      mx    = { name = "mx.tf-test", type = "MX", content = "mx1.example.net", priority = 20 }
      txt   = { name = "txt.tf-test", type = "TXT", content = "tf-test-v2" }
      srv   = { name = "_sip._tcp.tf-test", type = "SRV", priority = 10, data = { priority = 10, weight = 5, port = 5061, target = "sip.example.net" } }
      caa   = { name = "caa.tf-test", type = "CAA", data = { flags = 0, tag = "issue", value = "pki.goog" } }
      naptr = { name = "naptr.tf-test", type = "NAPTR", data = { order = 100, preference = 20, flags = "S", service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.net." } }
      sshfp = { name = "sshfp.tf-test", type = "SSHFP", data = { algorithm = 4, type = 2, fingerprint = "FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210" } }
      tlsa  = { name = "_443._tcp.tlsa.tf-test", type = "TLSA", data = { usage = 3, selector = 1, matching_type = 1, certificate = "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210" } }
      https = { name = "https.tf-test", type = "HTTPS", data = { priority = 1, target = ".", value = "alpn=\"h3\"" } }
      svcb  = { name = "_dns.svcb.tf-test", type = "SVCB", data = { priority = 2, target = "dns.example.net.", value = "alpn=\"dot\"" } }
      uri   = { name = "_http._tcp.uri.tf-test", type = "URI", priority = 20, data = { weight = 1, target = "https://example.net/" } }
      loc   = { name = "loc.tf-test", type = "LOC", data = { lat_degrees = 48, lat_minutes = 51, lat_seconds = 24, lat_direction = "N", long_degrees = 2, long_minutes = 21, long_seconds = 7, long_direction = "E", altitude = 40, size = 1, precision_horz = 10000, precision_vert = 10 } }
    }
  }

  assert {
    condition     = alltrue([for record in cloudflare_dns_record.this : record.id != null && record.modified_on != null])
    error_message = "A plan after the update must leave every record unchanged."
  }
}
