output "access_identity_provider_ids" {
  description = "IDs of the identity providers, by key of `access_identity_providers`."
  value       = { for key, idp in cloudflare_zero_trust_access_identity_provider.this : key => idp.id }
}

output "access_identity_provider_scim_configs" {
  description = "SCIM settings of the identity providers, by key of `access_identity_providers`, as the provider returns them. Give the identity provider `scim_base_url` and `secret`. Cloudflare returns `secret` only when SCIM is first enabled: a provider imported with SCIM on has none, see [SCIM](#scim)."
  value       = { for key, idp in cloudflare_zero_trust_access_identity_provider.this : key => idp.scim_config }
  sensitive   = true
}
