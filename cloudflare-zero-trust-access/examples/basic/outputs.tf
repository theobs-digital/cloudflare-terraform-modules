output "wiki_aud" {
  description = "Audience tag (AUD) of the wiki application, which the origin checks in the Access token."
  value       = module.access.access_application_auds["wiki"]
}
