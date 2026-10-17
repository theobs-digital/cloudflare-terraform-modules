output "access_identity_provider_ids" {
  description = "IDs of the identity providers, by key of `access_identity_providers`."
  value       = { for key, idp in cloudflare_zero_trust_access_identity_provider.this : key => idp.id }
}

output "access_identity_provider_scim_configs" {
  description = "SCIM settings of the identity providers, by key of `access_identity_providers`, as the provider returns them. Give the identity provider `scim_base_url` and `secret`. Cloudflare returns `secret` only when SCIM is first enabled: a provider imported with SCIM on has none, see [SCIM](#scim)."
  value       = { for key, idp in cloudflare_zero_trust_access_identity_provider.this : key => idp.scim_config }
  sensitive   = true
}

output "access_group_ids" {
  description = "IDs of the Access groups, by key of `access_groups`."
  value       = { for key, group in cloudflare_zero_trust_access_group.this : key => group.id }
}

output "access_policy_ids" {
  description = "IDs of the reusable Access policies, by key of `access_policies`."
  value       = { for key, policy in cloudflare_zero_trust_access_policy.this : key => policy.id }
}

output "access_application_ids" {
  description = "IDs of the Access applications, by key of `access_applications`."
  value       = { for key, app in cloudflare_zero_trust_access_application.this : key => app.id }
}

output "access_application_auds" {
  description = "Audience tags (AUD) of the Access applications, by key of `access_applications`. The origin checks the `aud` claim of the Access token against it."
  value       = { for key, app in cloudflare_zero_trust_access_application.this : key => app.aud }
}

output "access_application_saas_apps" {
  description = "SaaS settings of the Access applications, by key of `access_applications`, as the provider returns them, with what Cloudflare generates: `client_id` and `client_secret` (OIDC), `idp_entity_id`, `sso_endpoint` and `public_key` (SAML). `null` for an application without `saas_app`. Cloudflare returns `client_secret` only at creation, see [SaaS applications](#saas-applications)."
  value       = { for key, app in cloudflare_zero_trust_access_application.this : key => app.saas_app }
  sensitive   = true
}
