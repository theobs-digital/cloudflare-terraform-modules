output "application_auds" {
  description = "Audience tags (AUD) of the applications, by key, which each origin checks in the Access token."
  value       = module.access.access_application_auds
}

output "crm_oidc" {
  description = "Client ID and secret of the CRM, to set in the CRM's OIDC settings."
  value = {
    client_id     = module.access.access_application_saas_apps["crm"].client_id
    client_secret = module.access.access_application_saas_apps["crm"].client_secret
  }
  sensitive = true
}

output "entra_scim" {
  description = "SCIM base URL and secret to give Microsoft Entra ID."
  value = {
    scim_base_url = module.access.access_identity_provider_scim_configs["entra"].scim_base_url
    secret        = module.access.access_identity_provider_scim_configs["entra"].secret
  }
  sensitive = true
}

output "ci_client_id" {
  description = "Client ID of the CI service token, sent in the CF-Access-Client-Id header."
  value       = module.access.access_service_token_client_ids["ci"]
}

output "ci_client_secret" {
  description = "Client secret of the CI service token, sent in the CF-Access-Client-Secret header."
  value       = module.access.access_service_token_client_secrets["ci"]
  sensitive   = true
}

output "ssh_ca_public_key" {
  description = "Public key of the SSH certificate authority, to set in TrustedUserCAKeys on the SSH servers."
  value       = module.access.access_short_lived_certificate_public_keys["ssh"]
}
