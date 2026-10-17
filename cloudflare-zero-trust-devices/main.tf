resource "cloudflare_zero_trust_device_settings" "this" {
  count = var.settings == null ? 0 : 1

  account_id                            = var.account_id
  disable_for_time                      = var.settings.disable_for_time
  external_emergency_signal_enabled     = var.settings.external_emergency_signal_enabled
  external_emergency_signal_fingerprint = var.settings.external_emergency_signal_fingerprint
  external_emergency_signal_interval    = var.settings.external_emergency_signal_interval
  external_emergency_signal_url         = var.settings.external_emergency_signal_url
  gateway_proxy_enabled                 = var.settings.gateway_proxy_enabled
  gateway_udp_proxy_enabled             = var.settings.gateway_udp_proxy_enabled
  root_certificate_installation_enabled = var.settings.root_certificate_installation_enabled
  use_zt_virtual_ip                     = var.settings.use_zt_virtual_ip
}

resource "cloudflare_zero_trust_device_default_profile" "this" {
  count = var.default_profile == null ? 0 : 1

  account_id                     = var.account_id
  allow_mode_switch              = var.default_profile.allow_mode_switch
  allow_updates                  = var.default_profile.allow_updates
  allowed_to_leave               = var.default_profile.allowed_to_leave
  auto_connect                   = var.default_profile.auto_connect
  captive_portal                 = var.default_profile.captive_portal
  disable_auto_fallback          = var.default_profile.disable_auto_fallback
  dns_search_suffixes            = var.default_profile.dns_search_suffixes
  exclude                        = var.default_profile.exclude
  exclude_office_ips             = var.default_profile.exclude_office_ips
  global_acceleration            = var.default_profile.global_acceleration
  include                        = var.default_profile.include
  lan_allow_minutes              = var.default_profile.lan_allow_minutes
  lan_allow_subnet_size          = var.default_profile.lan_allow_subnet_size
  register_interface_ip_with_dns = var.default_profile.register_interface_ip_with_dns
  sccm_vpn_boundary_support      = var.default_profile.sccm_vpn_boundary_support
  service_mode_v2                = var.default_profile.service_mode_v2
  support_url                    = var.default_profile.support_url
  switch_locked                  = var.default_profile.switch_locked
  tunnel_protocol                = var.default_profile.tunnel_protocol
  uninstall_protection           = var.default_profile.uninstall_protection
  virtual_networks               = var.default_profile.virtual_networks
}

resource "cloudflare_zero_trust_device_default_profile_local_domain_fallback" "this" {
  count = var.default_profile_local_domain_fallback == null ? 0 : 1

  account_id = var.account_id
  domains    = var.default_profile_local_domain_fallback.domains

  # The default profile returns these domains in its computed
  # `fallback_domains`: changed first in the same apply, they fail its update
  # ("Provider produced inconsistent result after apply"), and parallel writes
  # to both get error 2077 ("policy was modified concurrently").
  depends_on = [cloudflare_zero_trust_device_default_profile.this]
}

resource "cloudflare_zero_trust_device_default_profile_certificates" "this" {
  for_each = var.default_profile_certificates

  zone_id = each.value.zone_id
  enabled = each.value.enabled
}
