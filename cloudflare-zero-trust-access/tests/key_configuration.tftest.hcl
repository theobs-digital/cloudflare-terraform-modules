mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "key_configuration_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_key_configuration.this) == 0
    error_message = "Without access_key_configuration, the module must not manage the rotation of the keys."
  }
}

run "key_configuration" {
  command = plan

  variables {
    access_key_configuration = { key_rotation_interval_days = 42 }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_key_configuration.this[0].account_id == var.account_id &&
      cloudflare_zero_trust_access_key_configuration.this[0].key_rotation_interval_days == 42
    )
    error_message = "key_rotation_interval_days must reach the key configuration of account_id."
  }
}
