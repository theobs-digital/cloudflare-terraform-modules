mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_mtls_certificate" {
    defaults = {
      id = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
      # Settings unlike the ones the tests give, which must win.
      associated_hostnames = ["computed.example.net"]
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_mtls" {
  command = plan

  assert {
    condition = (
      length(cloudflare_zero_trust_access_mtls_certificate.this) == 0 &&
      length(cloudflare_zero_trust_access_mtls_hostname_settings.this) == 0
    )
    error_message = "Without access_mtls_certificates and access_mtls_hostname_settings, the module must manage neither."
  }
}

run "mtls_certificate" {
  variables {
    access_mtls_certificates = {
      corp = {
        name                 = "Corporate CA"
        certificate          = "-----BEGIN CERTIFICATE-----\nMIIBhTCCASugAwIBAgIUZ3J0\n-----END CERTIFICATE-----\n"
        associated_hostnames = ["admin.example.com", "api.example.com"]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_mtls_certificate.this["corp"].account_id == var.account_id &&
      cloudflare_zero_trust_access_mtls_certificate.this["corp"].name == "Corporate CA" &&
      cloudflare_zero_trust_access_mtls_certificate.this["corp"].certificate == var.access_mtls_certificates["corp"].certificate
    )
    error_message = "The certificate must belong to account_id, with name and certificate as given."
  }

  assert {
    condition     = cloudflare_zero_trust_access_mtls_certificate.this["corp"].associated_hostnames == toset(["admin.example.com", "api.example.com"])
    error_message = "associated_hostnames must reach the certificate."
  }

  assert {
    condition     = output.access_mtls_certificate_ids == { corp = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415" }
    error_message = "access_mtls_certificate_ids must give the ID of each certificate."
  }
}

run "mtls_hostname_settings" {
  command = plan

  variables {
    access_mtls_hostname_settings = {
      settings = [
        { hostname = "admin.example.com", china_network = false, client_certificate_forwarding = true },
        { hostname = "api.example.com", china_network = true, client_certificate_forwarding = false },
      ]
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_mtls_hostname_settings.this[0].account_id == var.account_id &&
      cloudflare_zero_trust_access_mtls_hostname_settings.this[0].settings == var.access_mtls_hostname_settings.settings
    )
    error_message = "Every hostname setting must reach the settings of account_id, in order."
  }
}
