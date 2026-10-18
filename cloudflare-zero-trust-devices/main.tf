resource "cloudflare_zero_trust_device_settings" "this" {
  count = var.device_settings == null ? 0 : 1

  account_id                            = var.account_id
  disable_for_time                      = var.device_settings.disable_for_time
  external_emergency_signal_enabled     = var.device_settings.external_emergency_signal_enabled
  external_emergency_signal_fingerprint = var.device_settings.external_emergency_signal_fingerprint
  external_emergency_signal_interval    = var.device_settings.external_emergency_signal_interval
  external_emergency_signal_url         = var.device_settings.external_emergency_signal_url
  gateway_proxy_enabled                 = var.device_settings.gateway_proxy_enabled
  gateway_udp_proxy_enabled             = var.device_settings.gateway_udp_proxy_enabled
  root_certificate_installation_enabled = var.device_settings.root_certificate_installation_enabled
  use_zt_virtual_ip                     = var.device_settings.use_zt_virtual_ip
}

resource "cloudflare_zero_trust_device_default_profile" "this" {
  count = var.device_default_profile == null ? 0 : 1

  account_id                     = var.account_id
  allow_mode_switch              = var.device_default_profile.allow_mode_switch
  allow_updates                  = var.device_default_profile.allow_updates
  allowed_to_leave               = var.device_default_profile.allowed_to_leave
  auto_connect                   = var.device_default_profile.auto_connect
  captive_portal                 = var.device_default_profile.captive_portal
  disable_auto_fallback          = var.device_default_profile.disable_auto_fallback
  dns_search_suffixes            = var.device_default_profile.dns_search_suffixes
  exclude                        = var.device_default_profile.exclude
  exclude_office_ips             = var.device_default_profile.exclude_office_ips
  global_acceleration            = var.device_default_profile.global_acceleration
  include                        = var.device_default_profile.include
  lan_allow_minutes              = var.device_default_profile.lan_allow_minutes
  lan_allow_subnet_size          = var.device_default_profile.lan_allow_subnet_size
  register_interface_ip_with_dns = var.device_default_profile.register_interface_ip_with_dns
  sccm_vpn_boundary_support      = var.device_default_profile.sccm_vpn_boundary_support
  service_mode_v2                = var.device_default_profile.service_mode_v2
  support_url                    = var.device_default_profile.support_url
  switch_locked                  = var.device_default_profile.switch_locked
  tunnel_protocol                = var.device_default_profile.tunnel_protocol
  uninstall_protection           = var.device_default_profile.uninstall_protection
  virtual_networks               = var.device_default_profile.virtual_networks
}

resource "cloudflare_zero_trust_device_default_profile_local_domain_fallback" "this" {
  count = var.device_default_profile_local_domain_fallback == null ? 0 : 1

  account_id = var.account_id
  domains    = var.device_default_profile_local_domain_fallback.domains

  # The default profile returns these domains in its computed
  # `fallback_domains`: changed first in the same apply, they fail its update
  # ("Provider produced inconsistent result after apply"), and parallel writes
  # to both get error 2077 ("policy was modified concurrently").
  depends_on = [cloudflare_zero_trust_device_default_profile.this]
}

resource "cloudflare_zero_trust_device_default_profile_certificates" "this" {
  for_each = var.device_default_profile_certificates

  zone_id = each.value.zone_id
  enabled = each.value.enabled
}

resource "cloudflare_zero_trust_device_custom_profile" "this" {
  for_each = var.device_custom_profiles

  account_id                     = var.account_id
  name                           = each.value.name
  allow_mode_switch              = each.value.allow_mode_switch
  allow_updates                  = each.value.allow_updates
  allowed_to_leave               = each.value.allowed_to_leave
  auto_connect                   = each.value.auto_connect
  browser_extension_config       = each.value.browser_extension_config
  captive_portal                 = each.value.captive_portal
  description                    = each.value.description
  disable_auto_fallback          = each.value.disable_auto_fallback
  dns_search_suffixes            = each.value.dns_search_suffixes
  enabled                        = each.value.enabled
  exclude                        = each.value.exclude
  exclude_office_ips             = each.value.exclude_office_ips
  global_acceleration            = each.value.global_acceleration
  include                        = each.value.include
  lan_allow_minutes              = each.value.lan_allow_minutes
  lan_allow_subnet_size          = each.value.lan_allow_subnet_size
  match                          = each.value.match
  precedence                     = each.value.precedence
  profile_type                   = each.value.profile_type
  register_interface_ip_with_dns = each.value.register_interface_ip_with_dns
  sccm_vpn_boundary_support      = each.value.sccm_vpn_boundary_support
  service_mode_v2                = each.value.service_mode_v2
  support_url                    = each.value.support_url
  switch_locked                  = each.value.switch_locked
  tunnel_protocol                = each.value.tunnel_protocol
  uninstall_protection           = each.value.uninstall_protection
  virtual_networks               = each.value.virtual_networks
}

resource "cloudflare_zero_trust_device_custom_profile_local_domain_fallback" "this" {
  for_each = var.device_custom_profile_local_domain_fallbacks

  account_id = var.account_id
  policy_id  = each.value.policy_id
  domains    = each.value.domains

  # As for the default profile, even with a policy_id written literally:
  # written in parallel, the profile update fails on `fallback_domains`.
  depends_on = [cloudflare_zero_trust_device_custom_profile.this]
}

resource "cloudflare_zero_trust_device_managed_networks" "this" {
  for_each = var.device_managed_networks

  account_id = var.account_id
  name       = each.value.name
  type       = each.value.type
  config     = each.value.config
}

resource "cloudflare_zero_trust_device_posture_integration" "this" {
  for_each = var.device_posture_integrations

  account_id = var.account_id
  name       = each.value.name
  type       = each.value.type
  interval   = each.value.interval
  config     = each.value.config
}

resource "cloudflare_zero_trust_device_posture_rule" "this" {
  for_each = var.device_posture_rules

  account_id  = var.account_id
  name        = each.value.name
  type        = each.value.type
  description = each.value.description
  expiration  = each.value.expiration
  input       = each.value.input
  match       = each.value.match
  schedule    = each.value.schedule
}
