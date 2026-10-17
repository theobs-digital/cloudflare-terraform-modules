mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_service_token" {
    defaults = {
      id            = "3537a672-e4d8-4d89-aab9-26cb622918a1"
      client_id     = "88bf3b6d86161464f6509f7219099e57.access"
      client_secret = "bdd31cbc4dec990953e39163fbbb194c93313ca9f0a6e420346af9d326b1d2a5"
      # Settings unlike the ones the tests give, which must win.
      client_secret_version = 7
      duration              = "forever"
      enabled               = false
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_service_tokens" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_service_token.this) == 0
    error_message = "Without access_service_tokens, the module must not create any."
  }
}

run "service_token_minimal" {
  command = plan

  variables {
    access_service_tokens = {
      ci = { name = "CI" }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_service_token.this["ci"].account_id == var.account_id &&
      cloudflare_zero_trust_access_service_token.this["ci"].name == "CI"
    )
    error_message = "The service token must belong to account_id, with name as given."
  }

  assert {
    condition     = cloudflare_zero_trust_access_service_token.this["ci"].previous_client_secret_expires_at == null
    error_message = "previous_client_secret_expires_at left out must stay unset."
  }
}

run "service_token" {
  variables {
    access_service_tokens = {
      ci = {
        name                              = "CI"
        client_secret_version             = 2
        duration                          = "8760h"
        enabled                           = true
        previous_client_secret_expires_at = "2026-10-18T12:00:00Z"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_service_token.this["ci"].client_secret_version == 2 &&
      cloudflare_zero_trust_access_service_token.this["ci"].duration == "8760h" &&
      cloudflare_zero_trust_access_service_token.this["ci"].enabled == true &&
      cloudflare_zero_trust_access_service_token.this["ci"].previous_client_secret_expires_at == "2026-10-18T12:00:00Z"
    )
    error_message = "client_secret_version, duration, enabled and previous_client_secret_expires_at must reach the service token."
  }

  assert {
    condition = (
      output.access_service_token_ids == { ci = "3537a672-e4d8-4d89-aab9-26cb622918a1" } &&
      output.access_service_token_client_ids == { ci = "88bf3b6d86161464f6509f7219099e57.access" } &&
      nonsensitive(output.access_service_token_client_secrets["ci"]) == "bdd31cbc4dec990953e39163fbbb194c93313ca9f0a6e420346af9d326b1d2a5"
    )
    error_message = "The outputs must give the ID, client ID and client secret of each service token."
  }
}
