# Singleton: the provider's create updates the existing organization, its
# destroy only forgets it.
resource "cloudflare_zero_trust_organization" "this" {
  count = var.organization == null ? 0 : 1

  account_id                                  = var.account_id
  allow_authenticate_via_warp                 = var.organization.allow_authenticate_via_warp
  auth_domain                                 = var.organization.auth_domain
  auto_redirect_to_identity                   = var.organization.auto_redirect_to_identity
  custom_pages                                = var.organization.custom_pages
  deny_unmatched_requests                     = var.organization.deny_unmatched_requests
  deny_unmatched_requests_exempted_zone_names = var.organization.deny_unmatched_requests_exempted_zone_names
  is_ui_read_only                             = var.organization.is_ui_read_only
  login_design                                = var.organization.login_design
  mfa_config                                  = var.organization.mfa_config
  mfa_configuration_allowed                   = var.organization.mfa_configuration_allowed
  mfa_piv_key_requirements                    = var.organization.mfa_piv_key_requirements
  mfa_required_for_all_apps                   = var.organization.mfa_required_for_all_apps
  name                                        = var.organization.name
  service_token_inactivity                    = var.organization.service_token_inactivity
  session_duration                            = var.organization.session_duration
  strict_service_token_auth                   = var.organization.strict_service_token_auth
  ui_read_only_toggle_reason                  = var.organization.ui_read_only_toggle_reason
  user_seat_expiration_inactive_time          = var.organization.user_seat_expiration_inactive_time
  warp_auth_non_browser_401                   = var.organization.warp_auth_non_browser_401
  warp_auth_session_duration                  = var.organization.warp_auth_session_duration
}

resource "cloudflare_zero_trust_access_identity_provider" "this" {
  for_each = var.access_identity_providers

  account_id              = var.account_id
  name                    = each.value.name
  type                    = each.value.type
  config                  = each.value.config
  read_only               = each.value.read_only
  saml_certificate_set_id = each.value.saml_certificate_set_id
  scim_config             = each.value.scim_config
}

resource "cloudflare_zero_trust_access_group" "this" {
  for_each = var.access_groups

  account_id = var.account_id
  name       = each.value.name
  include    = each.value.include
  exclude    = each.value.exclude
  is_default = each.value.is_default
  require    = each.value.require
}

resource "cloudflare_zero_trust_access_policy" "this" {
  for_each = var.access_policies

  account_id                     = var.account_id
  decision                       = each.value.decision
  name                           = each.value.name
  approval_groups                = each.value.approval_groups
  approval_required              = each.value.approval_required
  connection_rules               = each.value.connection_rules
  exclude                        = each.value.exclude
  include                        = each.value.include
  isolation_required             = each.value.isolation_required
  mfa_config                     = each.value.mfa_config
  purpose_justification_prompt   = each.value.purpose_justification_prompt
  purpose_justification_required = each.value.purpose_justification_required
  require                        = each.value.require
  session_duration               = each.value.session_duration
}
