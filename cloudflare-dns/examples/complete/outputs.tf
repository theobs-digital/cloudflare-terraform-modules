output "zone_id" {
  description = "ID of the zone."
  value       = module.dns.zone_id
}

output "status" {
  description = "Status of the zone, `pending` until the registrar delegates the domain."
  value       = module.dns.status
}

output "name_servers" {
  description = "Name servers to set at the registrar."
  value       = module.dns.name_servers
}

output "dnssec" {
  description = "DS record to give the registrar, whole in `ds` or field by field."
  value       = module.dns.dnssec
}

output "record_ids" {
  description = "IDs of the DNS records, by key of `records`."
  value       = module.dns.record_ids
}
