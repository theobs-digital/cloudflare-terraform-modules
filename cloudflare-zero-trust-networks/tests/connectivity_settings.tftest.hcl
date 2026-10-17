mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "settings_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_connectivity_settings.this) == 0
    error_message = "Without connectivity_settings, the module must not manage the connectivity settings."
  }
}

run "settings" {
  variables {
    connectivity_settings = {
      icmp_proxy_enabled   = true
      offramp_warp_enabled = false
    }
  }

  assert {
    condition     = cloudflare_zero_trust_connectivity_settings.this[0].account_id == var.account_id
    error_message = "The connectivity settings must be those of account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_connectivity_settings.this[0].icmp_proxy_enabled == true && cloudflare_zero_trust_connectivity_settings.this[0].offramp_warp_enabled == false
    error_message = "icmp_proxy_enabled and offramp_warp_enabled must reach the connectivity settings."
  }
}

run "one_setting" {
  command = plan

  variables {
    connectivity_settings = {
      offramp_warp_enabled = true
    }
  }

  assert {
    condition     = cloudflare_zero_trust_connectivity_settings.this[0].offramp_warp_enabled == true && cloudflare_zero_trust_connectivity_settings.this[0].icmp_proxy_enabled == null
    error_message = "Left out, a setting must stay unset."
  }
}
