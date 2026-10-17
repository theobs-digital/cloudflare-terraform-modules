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

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = var.access_applications

  account_id                      = var.account_id
  name                            = each.value.name
  type                            = each.value.type
  allow_authenticate_via_warp     = each.value.allow_authenticate_via_warp
  allow_iframe                    = each.value.allow_iframe
  allowed_idps                    = each.value.allowed_idps
  app_launcher_logo_url           = each.value.app_launcher_logo_url
  app_launcher_visible            = each.value.app_launcher_visible
  auto_redirect_to_identity       = each.value.auto_redirect_to_identity
  bg_color                        = each.value.bg_color
  cors_headers                    = each.value.cors_headers
  custom_deny_message             = each.value.custom_deny_message
  custom_deny_url                 = each.value.custom_deny_url
  custom_non_identity_deny_url    = each.value.custom_non_identity_deny_url
  custom_pages                    = each.value.custom_pages
  destinations                    = each.value.destinations
  domain                          = each.value.domain
  enable_binding_cookie           = each.value.enable_binding_cookie
  footer_links                    = each.value.footer_links
  header_bg_color                 = each.value.header_bg_color
  http_only_cookie_attribute      = each.value.http_only_cookie_attribute
  landing_page_design             = each.value.landing_page_design
  logo_url                        = each.value.logo_url
  mfa_config                      = each.value.mfa_config
  oauth_configuration             = each.value.oauth_configuration
  options_preflight_bypass        = each.value.options_preflight_bypass
  path_cookie_attribute           = each.value.path_cookie_attribute
  policies                        = each.value.policies
  read_service_tokens_from_header = each.value.read_service_tokens_from_header
  saas_app                        = each.value.saas_app
  same_site_cookie_attribute      = each.value.same_site_cookie_attribute
  scim_config                     = each.value.scim_config
  service_auth_401_redirect       = each.value.service_auth_401_redirect
  session_duration                = each.value.session_duration
  skip_app_launcher_login_page    = each.value.skip_app_launcher_login_page
  skip_interstitial               = each.value.skip_interstitial
  tags                            = each.value.tags
  target_criteria                 = each.value.target_criteria
}

resource "cloudflare_zero_trust_access_service_token" "this" {
  for_each = var.access_service_tokens

  account_id                        = var.account_id
  name                              = each.value.name
  client_secret_version             = each.value.client_secret_version
  duration                          = each.value.duration
  enabled                           = each.value.enabled
  previous_client_secret_expires_at = each.value.previous_client_secret_expires_at
}

resource "cloudflare_zero_trust_access_mtls_certificate" "this" {
  for_each = var.access_mtls_certificates

  account_id           = var.account_id
  certificate          = each.value.certificate
  name                 = each.value.name
  associated_hostnames = each.value.associated_hostnames
}

# Singleton: the provider's create updates the list of the account, its
# destroy only forgets it.
resource "cloudflare_zero_trust_access_mtls_hostname_settings" "this" {
  count = var.access_mtls_hostname_settings == null ? 0 : 1

  account_id = var.account_id
  settings   = var.access_mtls_hostname_settings.settings
}

resource "cloudflare_zero_trust_access_short_lived_certificate" "this" {
  for_each = var.access_short_lived_certificates

  account_id = var.account_id
  app_id     = each.value.app_id
}

resource "cloudflare_zero_trust_access_tag" "this" {
  for_each = var.access_tags

  account_id = var.account_id
  name       = each.value.name
}

resource "cloudflare_zero_trust_access_custom_page" "this" {
  for_each = var.access_custom_pages

  account_id       = var.account_id
  custom_html      = each.value.custom_html
  name             = each.value.name
  type             = each.value.type
  contract_version = each.value.contract_version
}

# Singleton: the provider's create updates the account's setting, its destroy
# only forgets it.
resource "cloudflare_zero_trust_access_key_configuration" "this" {
  count = var.access_key_configuration == null ? 0 : 1

  account_id                 = var.account_id
  key_rotation_interval_days = var.access_key_configuration.key_rotation_interval_days
}

resource "cloudflare_zero_trust_access_infrastructure_target" "this" {
  for_each = var.access_infrastructure_targets

  account_id = var.account_id
  hostname   = each.value.hostname
  ip         = each.value.ip
  tags       = each.value.tags
}

resource "cloudflare_zero_trust_access_ai_controls_mcp_server" "this" {
  for_each = var.access_ai_controls_mcp_servers

  account_id                       = var.account_id
  auth_type                        = each.value.auth_type
  hostname                         = each.value.hostname
  id                               = each.value.id
  name                             = each.value.name
  auth_credentials                 = each.value.auth_credentials
  client_secret                    = each.value.client_secret
  description                      = each.value.description
  is_shared_oauth_callback_enabled = each.value.is_shared_oauth_callback_enabled
  secure_web_gateway               = each.value.secure_web_gateway
  updated_prompts                  = each.value.updated_prompts
  updated_tools                    = each.value.updated_tools
}

resource "cloudflare_zero_trust_access_ai_controls_mcp_portal" "this" {
  for_each = var.access_ai_controls_mcp_portals

  account_id         = var.account_id
  hostname           = each.value.hostname
  id                 = each.value.id
  name               = each.value.name
  code_mode          = each.value.code_mode
  description        = each.value.description
  secure_web_gateway = each.value.secure_web_gateway
  servers            = each.value.servers
}
