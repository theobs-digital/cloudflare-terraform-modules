mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_identity_provider" {
    defaults = {
      id = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
      # Settings unlike the ones the tests give, which must win.
      scim_config = {
        enabled                  = false
        identity_update_behavior = "no_action"
        scim_base_url            = "https://example.cloudflareaccess.com/populi/v1/abcd1234/scim/v2"
        seat_deprovision         = true
        secret                   = "c2NpbS1zZWNyZXQ="
        user_deprovision         = false
      }
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_identity_providers" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_identity_provider.this) == 0
    error_message = "Without access_identity_providers, the module must not create any."
  }
}

# The one-time PIN takes no setting. Set up from the dashboard, it can have an
# empty name.
run "one_time_pin" {
  command = plan

  variables {
    access_identity_providers = {
      otp = { name = "", type = "onetimepin", config = {} }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["otp"].account_id == var.account_id &&
      cloudflare_zero_trust_access_identity_provider.this["otp"].name == "" &&
      cloudflare_zero_trust_access_identity_provider.this["otp"].type == "onetimepin"
    )
    error_message = "The provider must belong to account_id, with name and type as given."
  }

  assert {
    condition = alltrue([
      for field, value in cloudflare_zero_trust_access_identity_provider.this["otp"].config : value == null
      if !contains(["enable_encryption", "login_page_auto_prompt", "redirect_url", "restrict_to_account_members"], field)
    ])
    error_message = "Fields left out of config must stay unset, but the computed ones."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["otp"].read_only == null &&
      cloudflare_zero_trust_access_identity_provider.this["otp"].saml_certificate_set_id == null
    )
    error_message = "read_only and saml_certificate_set_id must stay unset."
  }
}

run "oidc" {
  variables {
    access_identity_providers = {
      oidc = {
        name = "Example OIDC"
        type = "oidc"
        config = {
          auth_url                    = "https://idp.example.com/oauth2/authorize"
          certs_url                   = "https://idp.example.com/oauth2/keys"
          claims                      = ["groups"]
          client_id                   = "example-client"
          client_secret               = "example-secret"
          email_claim_name            = "email"
          pkce_enabled                = true
          restrict_to_account_members = false
          scopes                      = ["openid", "email", "profile"]
          token_url                   = "https://idp.example.com/oauth2/token"
        }
        scim_config = {
          enabled                  = true
          identity_update_behavior = "automatic"
          seat_deprovision         = false
          user_deprovision         = true
        }
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.auth_url == "https://idp.example.com/oauth2/authorize" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.certs_url == "https://idp.example.com/oauth2/keys" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.token_url == "https://idp.example.com/oauth2/token" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.scopes == tolist(["openid", "email", "profile"])
    )
    error_message = "auth_url, certs_url, token_url and scopes must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.claims == tolist(["groups"]) &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.client_id == "example-client" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.client_secret == "example-secret" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.email_claim_name == "email" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.pkce_enabled == true &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].config.restrict_to_account_members == false
    )
    error_message = "claims, client_id, client_secret, email_claim_name, pkce_enabled and restrict_to_account_members must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["oidc"].scim_config.enabled == true &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].scim_config.identity_update_behavior == "automatic" &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].scim_config.seat_deprovision == false &&
      cloudflare_zero_trust_access_identity_provider.this["oidc"].scim_config.user_deprovision == true
    )
    error_message = "Every field of scim_config must reach the provider."
  }

  assert {
    condition     = output.access_identity_provider_ids == { oidc = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415" }
    error_message = "access_identity_provider_ids must give the ID of each provider, by key."
  }

  assert {
    condition = (
      nonsensitive(output.access_identity_provider_scim_configs["oidc"].secret) == "c2NpbS1zZWNyZXQ=" &&
      nonsensitive(output.access_identity_provider_scim_configs["oidc"].scim_base_url) == "https://example.cloudflareaccess.com/populi/v1/abcd1234/scim/v2"
    )
    error_message = "access_identity_provider_scim_configs must give the SCIM base URL and secret Cloudflare returns, by key."
  }
}

run "saml" {
  command = plan

  variables {
    access_identity_providers = {
      saml = {
        name = "Example SAML"
        type = "saml"
        config = {
          attributes           = ["group", "department"]
          email_attribute_name = "email"
          enable_encryption    = true
          force_authn          = true
          header_attributes    = [{ attribute_name = "department", header_name = "X-Department" }]
          idp_public_certs     = ["MIIDpDCCAoygAwIBAgIGAV2ka+55MA0GCSqGSIb3DQEBCwUAMIGSMQswCQ"]
          issuer_url           = "https://idp.example.com/saml"
          max_sso_url_length   = 2048
          sign_request         = true
          sso_target_url       = "https://idp.example.com/saml/sso"
        }
        read_only               = false
        saml_certificate_set_id = "2bd3a1a5-0a2d-4c8a-9b5c-1e0f2d3c4b5a"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.attributes == tolist(["group", "department"]) &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.email_attribute_name == "email" &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.idp_public_certs == tolist(["MIIDpDCCAoygAwIBAgIGAV2ka+55MA0GCSqGSIb3DQEBCwUAMIGSMQswCQ"]) &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.issuer_url == "https://idp.example.com/saml" &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.sso_target_url == "https://idp.example.com/saml/sso"
    )
    error_message = "attributes, email_attribute_name, idp_public_certs, issuer_url and sso_target_url must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.enable_encryption == true &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.force_authn == true &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.max_sso_url_length == 2048 &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.sign_request == true
    )
    error_message = "enable_encryption, force_authn, max_sso_url_length and sign_request must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.header_attributes[0].attribute_name == "department" &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].config.header_attributes[0].header_name == "X-Department"
    )
    error_message = "header_attributes must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["saml"].read_only == false &&
      cloudflare_zero_trust_access_identity_provider.this["saml"].saml_certificate_set_id == "2bd3a1a5-0a2d-4c8a-9b5c-1e0f2d3c4b5a"
    )
    error_message = "read_only and saml_certificate_set_id must reach the provider."
  }
}

# The fields only some types take, one provider per type.
run "type_specific_fields" {
  command = plan

  variables {
    access_identity_providers = {
      entra = {
        name = "Microsoft Entra ID"
        type = "azureAD"
        config = {
          client_id                  = "example-client"
          client_secret              = "example-secret"
          conditional_access_enabled = true
          directory_id               = "9b2a1c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
          prompt                     = "select_account"
          support_groups             = true
        }
      }
      centrify = {
        name   = "Centrify"
        type   = "centrify"
        config = { centrify_account = "https://abc123.my.centrify.com/", centrify_app_id = "exampleapp" }
      }
      google_workspace = {
        name   = "Google Workspace"
        type   = "google-apps"
        config = { apps_domain = "example.com", use_login_hint = true }
      }
      okta = {
        name   = "Okta"
        type   = "okta"
        config = { authorization_server_id = "aus9o8wzkhckw9TLa0h7", okta_account = "https://example.okta.com" }
      }
      onelogin = {
        name   = "OneLogin"
        type   = "onelogin"
        config = { onelogin_account = "https://example.onelogin.com" }
      }
      pingone = {
        name   = "PingOne"
        type   = "pingone"
        config = { ping_env_id = "342b5660-0c32-4936-a5a4-ce21fae57b0a" }
      }
      passkeys = {
        name   = "Passkeys"
        type   = "passkeys"
        config = { login_page_auto_prompt = true }
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["entra"].config.conditional_access_enabled == true &&
      cloudflare_zero_trust_access_identity_provider.this["entra"].config.directory_id == "9b2a1c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d" &&
      cloudflare_zero_trust_access_identity_provider.this["entra"].config.prompt == "select_account" &&
      cloudflare_zero_trust_access_identity_provider.this["entra"].config.support_groups == true
    )
    error_message = "conditional_access_enabled, directory_id, prompt and support_groups must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["centrify"].config.centrify_account == "https://abc123.my.centrify.com/" &&
      cloudflare_zero_trust_access_identity_provider.this["centrify"].config.centrify_app_id == "exampleapp"
    )
    error_message = "centrify_account and centrify_app_id must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["google_workspace"].config.apps_domain == "example.com" &&
      cloudflare_zero_trust_access_identity_provider.this["google_workspace"].config.use_login_hint == true
    )
    error_message = "apps_domain and use_login_hint must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["okta"].config.authorization_server_id == "aus9o8wzkhckw9TLa0h7" &&
      cloudflare_zero_trust_access_identity_provider.this["okta"].config.okta_account == "https://example.okta.com"
    )
    error_message = "authorization_server_id and okta_account must reach the provider."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_identity_provider.this["onelogin"].config.onelogin_account == "https://example.onelogin.com" &&
      cloudflare_zero_trust_access_identity_provider.this["pingone"].config.ping_env_id == "342b5660-0c32-4936-a5a4-ce21fae57b0a"
    )
    error_message = "onelogin_account and ping_env_id must reach the provider."
  }

  assert {
    condition     = cloudflare_zero_trust_access_identity_provider.this["passkeys"].config.login_page_auto_prompt == true
    error_message = "login_page_auto_prompt must reach the provider."
  }
}
