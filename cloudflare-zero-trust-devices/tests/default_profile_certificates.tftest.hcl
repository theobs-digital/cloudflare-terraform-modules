mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "certificates_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_default_profile_certificates.this) == 0
    error_message = "Without default_profile_certificates, the module must not manage any zone."
  }
}

run "certificates" {
  variables {
    default_profile_certificates = {
      example = { zone_id = "9f1839b6152d298aca64c4e906b6d074", enabled = true }
      other   = { zone_id = "8ac8489932db6327334c9b6d58544cfe", enabled = false }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_default_profile_certificates.this["example"].zone_id == "9f1839b6152d298aca64c4e906b6d074" &&
      cloudflare_zero_trust_device_default_profile_certificates.this["example"].enabled == true
    )
    error_message = "Each entry must reach the certificate provisioning of its zone."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_default_profile_certificates.this["other"].zone_id == "8ac8489932db6327334c9b6d58544cfe" &&
      cloudflare_zero_trust_device_default_profile_certificates.this["other"].enabled == false
    )
    error_message = "Each zone must keep its own enabled value."
  }
}
