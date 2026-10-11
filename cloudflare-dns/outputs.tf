output "zone_id" {
  description = "ID of the zone."
  value       = local.zone.id
}

output "name" {
  description = "Domain name of the zone."
  value       = local.zone.name
}

output "status" {
  description = "Status of the zone: `initializing`, `pending`, `active` or `moved`. A new full zone stays `pending` until the registrar delegates the domain to `name_servers`."
  value       = local.zone.status
}

output "name_servers" {
  description = "Name servers Cloudflare assigned to the zone, to set at the registrar."
  value       = local.zone.name_servers
}

output "verification_key" {
  description = "Verification key for a partial zone setup."
  value       = local.zone.verification_key
}

output "record_ids" {
  description = "IDs of the DNS records, by key of `records`."
  value       = { for key, record in cloudflare_dns_record.this : key => record.id }
}

output "dnssec" {
  description = "DNSSEC of the zone, or `null` when the module does not manage it. Give the registrar the DS record, whole in `ds` or as its fields `key_tag`, `algorithm`, `digest_type` and `digest`. Some registrars ask for the DNSKEY record instead: `flags`, `algorithm` and `public_key`."
  value = one([
    for dnssec in cloudflare_zone_dnssec.this : {
      status           = dnssec.status
      ds               = dnssec.ds
      key_tag          = dnssec.key_tag
      algorithm        = dnssec.algorithm
      digest_type      = dnssec.digest_type
      digest_algorithm = dnssec.digest_algorithm
      digest           = dnssec.digest
      flags            = dnssec.flags
      key_type         = dnssec.key_type
      public_key       = dnssec.public_key
    }
  ])
}
