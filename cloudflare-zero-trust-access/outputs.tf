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

output "access_service_token_ids" {
  description = "IDs of the service tokens, by key of `access_service_tokens`. A rule `service_token` takes this ID as `token_id`."
  value       = { for key, token in cloudflare_zero_trust_access_service_token.this : key => token.id }
}

output "access_service_token_client_ids" {
  description = "Client IDs of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Id` header."
  value       = { for key, token in cloudflare_zero_trust_access_service_token.this : key => token.client_id }
}

output "access_service_token_client_secrets" {
  description = "Client secrets of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Secret` header. Cloudflare returns a secret only at creation and rotation: an imported token has none, see [Service tokens](#service-tokens)."
  value       = { for key, token in cloudflare_zero_trust_access_service_token.this : key => token.client_secret }
  sensitive   = true
}

output "access_mtls_certificate_ids" {
  description = "IDs of the mTLS certificates, by key of `access_mtls_certificates`."
  value       = { for key, cert in cloudflare_zero_trust_access_mtls_certificate.this : key => cert.id }
}

output "access_short_lived_certificate_public_keys" {
  description = "Public keys of the short-lived certificate CAs, by key of `access_short_lived_certificates`. SSH servers trust it with `TrustedUserCAKeys`."
  value       = { for key, ca in cloudflare_zero_trust_access_short_lived_certificate.this : key => ca.public_key }
}

output "access_tag_ids" {
  description = "IDs of the tags, by key of `access_tags`: a tag's ID is its name. An application takes them in `tags`."
  value       = { for key, tag in cloudflare_zero_trust_access_tag.this : key => tag.id }
}

output "access_custom_page_ids" {
  description = "IDs of the custom pages, by key of `access_custom_pages`. An application takes them in `custom_pages`, the organization in `custom_pages.forbidden` and `custom_pages.identity_denied`."
  value       = { for key, page in cloudflare_zero_trust_access_custom_page.this : key => page.id }
}

output "access_infrastructure_target_ids" {
  description = "IDs of the infrastructure targets, by key of `access_infrastructure_targets`."
  value       = { for key, target in cloudflare_zero_trust_access_infrastructure_target.this : key => target.id }
}

output "access_ai_controls_mcp_server_ids" {
  description = "IDs of the MCP servers, by key of `access_ai_controls_mcp_servers`. A portal takes them in `servers[*].server_id`, an `mcp` application in `destinations[*].mcp_server_id`."
  value       = { for key, server in cloudflare_zero_trust_access_ai_controls_mcp_server.this : key => server.id }
}
