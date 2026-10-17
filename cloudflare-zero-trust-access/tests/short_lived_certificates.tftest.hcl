mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_short_lived_certificate" {
    defaults = {
      public_key = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ open-ssh-ca@cloudflareaccess.org"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_short_lived_certificates" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_short_lived_certificate.this) == 0
    error_message = "Without access_short_lived_certificates, the module must not create any."
  }
}

run "short_lived_certificate" {
  variables {
    access_short_lived_certificates = {
      ssh = { app_id = "b6a1c4d2-7e3f-4a5b-9c8d-0e1f2a3b4c5d" }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_short_lived_certificate.this["ssh"].account_id == var.account_id &&
      cloudflare_zero_trust_access_short_lived_certificate.this["ssh"].app_id == "b6a1c4d2-7e3f-4a5b-9c8d-0e1f2a3b4c5d"
    )
    error_message = "The CA must belong to account_id, for the application of app_id."
  }

  assert {
    condition     = output.access_short_lived_certificate_public_keys == { ssh = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ open-ssh-ca@cloudflareaccess.org" }
    error_message = "access_short_lived_certificate_public_keys must give the public key of each CA."
  }
}
