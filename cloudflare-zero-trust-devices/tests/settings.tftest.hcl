mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "settings_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_settings.this) == 0
    error_message = "Without device_settings, the module must not manage the device settings."
  }
}

run "settings" {
  variables {
    device_settings = {
      disable_for_time                      = 3600
      external_emergency_signal_enabled     = true
      external_emergency_signal_fingerprint = "abd90f0f5a6b0b9a8f5c2f4b2c1d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d"
      external_emergency_signal_interval    = "5m"
      external_emergency_signal_url         = "https://192.0.2.10/signal"
      gateway_proxy_enabled                 = true
      gateway_udp_proxy_enabled             = true
      root_certificate_installation_enabled = true
      use_zt_virtual_ip                     = false
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_settings.this[0].account_id == var.account_id
    error_message = "The device settings must apply to account_id."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_settings.this[0].disable_for_time == 3600 &&
      cloudflare_zero_trust_device_settings.this[0].gateway_proxy_enabled == true &&
      cloudflare_zero_trust_device_settings.this[0].gateway_udp_proxy_enabled == true &&
      cloudflare_zero_trust_device_settings.this[0].root_certificate_installation_enabled == true &&
      cloudflare_zero_trust_device_settings.this[0].use_zt_virtual_ip == false
    )
    error_message = "disable_for_time, the Gateway proxy, the root certificate and use_zt_virtual_ip must reach the device settings."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_settings.this[0].external_emergency_signal_enabled == true &&
      cloudflare_zero_trust_device_settings.this[0].external_emergency_signal_fingerprint == var.device_settings.external_emergency_signal_fingerprint &&
      cloudflare_zero_trust_device_settings.this[0].external_emergency_signal_interval == "5m" &&
      cloudflare_zero_trust_device_settings.this[0].external_emergency_signal_url == "https://192.0.2.10/signal"
    )
    error_message = "The external emergency signal fields must reach the device settings."
  }
}

# What is left out stays null: the provider has no default for these
# attributes.
run "settings_partial" {
  command = plan

  variables {
    device_settings = {
      gateway_proxy_enabled = true
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_settings.this[0].gateway_proxy_enabled == true &&
      cloudflare_zero_trust_device_settings.this[0].gateway_udp_proxy_enabled == null &&
      cloudflare_zero_trust_device_settings.this[0].use_zt_virtual_ip == null
    )
    error_message = "Only the fields set must reach the device settings."
  }
}
