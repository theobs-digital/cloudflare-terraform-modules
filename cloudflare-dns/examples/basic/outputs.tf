output "name_servers" {
  description = "Name servers to set at the registrar."
  value       = module.dns.name_servers
}
