mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_application" {
    defaults = {
      id  = "b6a1c4d2-7e3f-4a5b-9c8d-0e1f2a3b4c5d"
      aud = "737646a56ab1df6ec9bddc7e5ca84eaf3b0768850f3ffb5d74f1534911fe3893"
      # Settings unlike the ones the tests give, which must win.
      app_launcher_visible         = false
      domain                       = "computed.example.net"
      http_only_cookie_attribute   = false
      name                         = "Computed"
      session_duration             = "30m"
      skip_app_launcher_login_page = true
      type                         = "warp"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_applications" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_application.this) == 0
    error_message = "Without access_applications, the module must not create any."
  }
}

run "self_hosted_minimal" {
  command = plan

  variables {
    access_applications = {
      app = {
        name         = "App"
        type         = "self_hosted"
        destinations = [{ type = "public", uri = "app.example.com" }]
        policies     = [{ id = "f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f" }]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].account_id == var.account_id &&
      cloudflare_zero_trust_access_application.this["app"].name == "App" &&
      cloudflare_zero_trust_access_application.this["app"].type == "self_hosted"
    )
    error_message = "The application must belong to account_id, with name and type as given."
  }

  assert {
    condition = (
      length(cloudflare_zero_trust_access_application.this["app"].destinations) == 1 &&
      cloudflare_zero_trust_access_application.this["app"].destinations[0].uri == "app.example.com"
    )
    error_message = "destinations must reach the application."
  }

  assert {
    condition = (
      length(cloudflare_zero_trust_access_application.this["app"].policies) == 1 &&
      cloudflare_zero_trust_access_application.this["app"].policies[0].id == "f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f"
    )
    error_message = "policies must reach the application."
  }

  # The provider's own fields of a policy written in the application stay
  # unset: only the reference goes out.
  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].policies[0].decision == null &&
      cloudflare_zero_trust_access_application.this["app"].policies[0].name == null &&
      cloudflare_zero_trust_access_application.this["app"].policies[0].include == null
    )
    error_message = "A policy reference must carry its ID only."
  }

  assert {
    condition = alltrue([
      for value in [
        cloudflare_zero_trust_access_application.this["app"].allow_authenticate_via_warp,
        cloudflare_zero_trust_access_application.this["app"].allow_iframe,
        cloudflare_zero_trust_access_application.this["app"].allowed_idps,
        cloudflare_zero_trust_access_application.this["app"].app_launcher_logo_url,
        cloudflare_zero_trust_access_application.this["app"].auto_redirect_to_identity,
        cloudflare_zero_trust_access_application.this["app"].bg_color,
        cloudflare_zero_trust_access_application.this["app"].cors_headers,
        cloudflare_zero_trust_access_application.this["app"].custom_deny_message,
        cloudflare_zero_trust_access_application.this["app"].custom_deny_url,
        cloudflare_zero_trust_access_application.this["app"].custom_non_identity_deny_url,
        cloudflare_zero_trust_access_application.this["app"].custom_pages,
        cloudflare_zero_trust_access_application.this["app"].enable_binding_cookie,
        cloudflare_zero_trust_access_application.this["app"].footer_links,
        cloudflare_zero_trust_access_application.this["app"].header_bg_color,
        cloudflare_zero_trust_access_application.this["app"].landing_page_design,
        cloudflare_zero_trust_access_application.this["app"].logo_url,
        cloudflare_zero_trust_access_application.this["app"].mfa_config,
        cloudflare_zero_trust_access_application.this["app"].oauth_configuration,
        cloudflare_zero_trust_access_application.this["app"].options_preflight_bypass,
        cloudflare_zero_trust_access_application.this["app"].path_cookie_attribute,
        cloudflare_zero_trust_access_application.this["app"].read_service_tokens_from_header,
        cloudflare_zero_trust_access_application.this["app"].saas_app,
        cloudflare_zero_trust_access_application.this["app"].same_site_cookie_attribute,
        cloudflare_zero_trust_access_application.this["app"].scim_config,
        cloudflare_zero_trust_access_application.this["app"].service_auth_401_redirect,
        cloudflare_zero_trust_access_application.this["app"].skip_interstitial,
        cloudflare_zero_trust_access_application.this["app"].tags,
        cloudflare_zero_trust_access_application.this["app"].target_criteria,
      ] : value == null
    ])
    error_message = "Attributes left out must stay unset."
  }
}

# One application per type, the 14 of the provider.
run "every_type" {
  command = plan

  variables {
    access_applications = {
      self_hosted    = { name = "Self-hosted", type = "self_hosted", domain = "app.example.com" }
      saas           = { name = "SaaS", type = "saas", saas_app = { auth_type = "saml", sp_entity_id = "https://saas.example.com", consumer_service_url = "https://saas.example.com/acs" } }
      ssh            = { name = "SSH", type = "ssh", domain = "ssh.example.com" }
      vnc            = { name = "VNC", type = "vnc", domain = "vnc.example.com" }
      app_launcher   = { type = "app_launcher" }
      warp           = { name = "Warp Login App", type = "warp" }
      biso           = { name = "Browser isolation", type = "biso" }
      bookmark       = { name = "Bookmark", type = "bookmark", domain = "https://wiki.example.com" }
      dash_sso       = { name = "Dashboard SSO", type = "dash_sso", saas_app = { auth_type = "saml" } }
      infrastructure = { name = "Infrastructure", type = "infrastructure", target_criteria = [{ port = 22, protocol = "SSH", include = { tags = { env = ["prod"] } } }] }
      rdp            = { name = "RDP", type = "rdp", domain = "rdp.example.com", target_criteria = [{ port = 3389, protocol = "RDP", include = { tags = { os = ["windows"] } } }] }
      mcp            = { name = "MCP server", type = "mcp", destinations = [{ type = "via_mcp_server_portal", mcp_server_id = "docs" }] }
      mcp_portal     = { name = "MCP portal", type = "mcp_portal", domain = "mcp.example.com" }
      proxy_endpoint = { name = "Gateway proxy", type = "proxy_endpoint", domain = "abcd123456.proxy.cloudflare-gateway.com" }
    }
  }

  assert {
    condition = alltrue([
      for key, app in cloudflare_zero_trust_access_application.this : app.type == key
    ]) && length(cloudflare_zero_trust_access_application.this) == 14
    error_message = "Each application must take its type."
  }

  assert {
    condition = alltrue([
      for key in ["self_hosted", "ssh", "vnc", "bookmark", "rdp", "mcp_portal", "proxy_endpoint"] :
      cloudflare_zero_trust_access_application.this[key].domain == var.access_applications[key].domain
    ])
    error_message = "domain must reach the application."
  }
}

run "self_hosted" {
  variables {
    access_applications = {
      app = {
        name = "App"
        type = "self_hosted"
        destinations = [
          { type = "public", uri = "app.example.com/admin" },
          { type = "private", cidr = "10.0.0.0/24", l4_protocol = "tcp", port_range = "443", vnet_id = "c4a2b1d0-5e6f-4a7b-8c9d-0e1f2a3b4c5d" },
          { type = "private", hostname = "app.internal.example" },
          { type = "worker", worker_id = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6" },
        ]
        domain = "app.example.com/admin"
        policies = [
          { id = "f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f", precedence = 1 },
          { id = "9a8b7c6d-5e4f-4a3b-2c1d-0e9f8a7b6c5d", precedence = 2 },
        ]
        allow_authenticate_via_warp  = true
        allow_iframe                 = true
        allowed_idps                 = ["f174e90a-fafe-4643-bbbc-4a0ed4fc8415"]
        app_launcher_visible         = true
        auto_redirect_to_identity    = true
        custom_deny_message          = "Ask the SRE team."
        custom_deny_url              = "https://example.com/denied"
        custom_non_identity_deny_url = "https://example.com/denied-device"
        custom_pages                 = ["d1c3780e-1d43-487e-9207-b1e26d58e600"]
        enable_binding_cookie        = true
        http_only_cookie_attribute   = true
        logo_url                     = "https://example.com/logo.svg"
        mfa_config = {
          allowed_authenticators = ["totp", "security_key"]
          mfa_disabled           = false
          session_duration       = "12h"
        }
        oauth_configuration = {
          enabled = true
          dynamic_client_registration = {
            allow_any_on_localhost = true
            allow_any_on_loopback  = false
            allowed_uris           = ["https://client.example.com/*"]
            enabled                = true
          }
          grant = {
            access_token_lifetime = "15m"
            session_duration      = "8h"
          }
        }
        path_cookie_attribute           = true
        read_service_tokens_from_header = "Authorization"
        same_site_cookie_attribute      = "strict"
        service_auth_401_redirect       = true
        session_duration                = "8h"
        skip_interstitial               = true
        tags                            = ["engineering"]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].destinations[1].cidr == "10.0.0.0/24" &&
      cloudflare_zero_trust_access_application.this["app"].destinations[1].l4_protocol == "tcp" &&
      cloudflare_zero_trust_access_application.this["app"].destinations[1].port_range == "443" &&
      cloudflare_zero_trust_access_application.this["app"].destinations[1].vnet_id == "c4a2b1d0-5e6f-4a7b-8c9d-0e1f2a3b4c5d" &&
      cloudflare_zero_trust_access_application.this["app"].destinations[2].hostname == "app.internal.example" &&
      cloudflare_zero_trust_access_application.this["app"].destinations[3].worker_id == "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"
    )
    error_message = "Every field of destinations must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].domain == "app.example.com/admin" &&
      [for policy in cloudflare_zero_trust_access_application.this["app"].policies : [policy.id, policy.precedence]] == [
        ["f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f", 1],
        ["9a8b7c6d-5e4f-4a3b-2c1d-0e9f8a7b6c5d", 2],
      ]
    )
    error_message = "domain and policies, with their precedence, must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].allow_authenticate_via_warp == true &&
      cloudflare_zero_trust_access_application.this["app"].allow_iframe == true &&
      cloudflare_zero_trust_access_application.this["app"].allowed_idps == toset(["f174e90a-fafe-4643-bbbc-4a0ed4fc8415"]) &&
      cloudflare_zero_trust_access_application.this["app"].app_launcher_visible == true &&
      cloudflare_zero_trust_access_application.this["app"].auto_redirect_to_identity == true &&
      cloudflare_zero_trust_access_application.this["app"].enable_binding_cookie == true &&
      cloudflare_zero_trust_access_application.this["app"].http_only_cookie_attribute == true &&
      cloudflare_zero_trust_access_application.this["app"].path_cookie_attribute == true &&
      cloudflare_zero_trust_access_application.this["app"].service_auth_401_redirect == true &&
      cloudflare_zero_trust_access_application.this["app"].skip_interstitial == true
    )
    error_message = "The identity and cookie settings must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].custom_deny_message == "Ask the SRE team." &&
      cloudflare_zero_trust_access_application.this["app"].custom_deny_url == "https://example.com/denied" &&
      cloudflare_zero_trust_access_application.this["app"].custom_non_identity_deny_url == "https://example.com/denied-device" &&
      cloudflare_zero_trust_access_application.this["app"].custom_pages == tolist(["d1c3780e-1d43-487e-9207-b1e26d58e600"]) &&
      cloudflare_zero_trust_access_application.this["app"].logo_url == "https://example.com/logo.svg"
    )
    error_message = "The deny settings, custom_pages and logo_url must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].mfa_config == var.access_applications["app"].mfa_config &&
      cloudflare_zero_trust_access_application.this["app"].oauth_configuration == var.access_applications["app"].oauth_configuration
    )
    error_message = "Every field of mfa_config and oauth_configuration must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["app"].read_service_tokens_from_header == "Authorization" &&
      cloudflare_zero_trust_access_application.this["app"].same_site_cookie_attribute == "strict" &&
      cloudflare_zero_trust_access_application.this["app"].session_duration == "8h" &&
      cloudflare_zero_trust_access_application.this["app"].tags == toset(["engineering"])
    )
    error_message = "read_service_tokens_from_header, same_site_cookie_attribute, session_duration and tags must reach the application."
  }

  assert {
    condition = (
      output.access_application_ids == { app = "b6a1c4d2-7e3f-4a5b-9c8d-0e1f2a3b4c5d" } &&
      output.access_application_auds == { app = "737646a56ab1df6ec9bddc7e5ca84eaf3b0768850f3ffb5d74f1534911fe3893" }
    )
    error_message = "access_application_ids and access_application_auds must give the ID and the AUD of each application, by key."
  }
}

# cors_headers and options_preflight_bypass exclude each other.
run "cors" {
  command = plan

  variables {
    access_applications = {
      cors = {
        name   = "CORS"
        type   = "self_hosted"
        domain = "cors.example.com"
        cors_headers = {
          allow_credentials = true
          allowed_headers   = ["X-Custom"]
          allowed_methods   = ["GET", "POST"]
          allowed_origins   = ["https://example.com"]
          max_age           = 600
        }
      }
      cors_all = {
        name         = "CORS for all"
        type         = "self_hosted"
        domain       = "cors-all.example.com"
        cors_headers = { allow_all_headers = true, allow_all_methods = true, allow_all_origins = true }
      }
      preflight = {
        name                     = "Preflight"
        type                     = "self_hosted"
        domain                   = "preflight.example.com"
        options_preflight_bypass = true
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["cors"].cors_headers == var.access_applications["cors"].cors_headers &&
      cloudflare_zero_trust_access_application.this["cors_all"].cors_headers == var.access_applications["cors_all"].cors_headers
    )
    error_message = "Every field of cors_headers must reach the application."
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.this["preflight"].options_preflight_bypass == true
    error_message = "options_preflight_bypass must reach the application."
  }
}

run "saas" {
  variables {
    access_applications = {
      saml = {
        name = "SAML"
        type = "saas"
        saas_app = {
          auth_type            = "saml"
          consumer_service_url = "https://saas.example.com/sso/saml/acs"
          sp_entity_id         = "https://saas.example.com"
          idp_entity_id        = "https://example.cloudflareaccess.com/cdn-cgi/access/sso/saml/abcd"
          name_id_format       = "email"
          sso_endpoint         = "https://example.cloudflareaccess.com/cdn-cgi/access/sso/saml/abcd"
          custom_attributes = [{
            friendly_name = "Groups"
            name          = "groups"
            name_format   = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
            required      = true
            source = {
              name        = "groups"
              name_by_idp = [{ idp_id = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415", source_name = "memberOf" }]
            }
          }]
          default_relay_state              = "https://saas.example.com/home"
          name_id_transform_jsonata        = "$substringBefore(email, '@')"
          saml_attribute_transform_jsonata = "$merge([{'team': groups[0]}])"
        }
        scim_config = {
          idp_uid    = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
          remote_uri = "https://saas.example.com/scim/v2"
          authentication = {
            scheme   = "httpbasic"
            user     = "scim"
            password = "example-password"
          }
          deactivate_on_delete = true
          enabled              = true
          mappings = [{
            schema            = "urn:ietf:params:scim:schemas:core:2.0:User"
            enabled           = true
            filter            = "title pr"
            operations        = { create = true, delete = false, update = true }
            strictness        = "strict"
            transform_jsonata = "$"
          }]
        }
      }
      oidc = {
        name = "OIDC"
        type = "saas"
        saas_app = {
          auth_type                        = "oidc"
          access_token_lifetime            = "10m"
          allow_pkce_without_client_secret = true
          app_launcher_url                 = "https://oidc.example.com/login"
          custom_claims = [{
            name     = "rank"
            required = true
            scope    = "profile"
            source   = { name = "rank", name_by_idp = { "f174e90a-fafe-4643-bbbc-4a0ed4fc8415" = "title" } }
          }]
          grant_types        = ["authorization_code_with_pkce", "refresh_tokens"]
          group_filter_regex = "^eng-"
          hybrid_and_implicit_options = {
            return_access_token_from_authorization_endpoint = true
            return_id_token_from_authorization_endpoint     = false
          }
          redirect_uris         = ["https://oidc.example.com/callback"]
          refresh_token_options = { lifetime = "30d" }
          scopes                = ["openid", "email", "profile"]
        }
        scim_config = {
          idp_uid    = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
          remote_uri = "https://oidc.example.com/scim/v2"
          authentication = {
            scheme            = "oauth2"
            authorization_url = "https://oidc.example.com/oauth/authorize"
            client_id         = "scim-client"
            client_secret     = "example-secret"
            scopes            = ["scim"]
            token_url         = "https://oidc.example.com/oauth/token"
          }
        }
      }
      bearer = {
        name     = "Bearer"
        type     = "saas"
        saas_app = { auth_type = "saml", sp_entity_id = "https://bearer.example.com", consumer_service_url = "https://bearer.example.com/acs" }
        scim_config = {
          idp_uid        = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
          remote_uri     = "https://bearer.example.com/scim/v2"
          authentication = { scheme = "oauthbearertoken", token = "example-token" }
        }
      }
    }
  }

  assert {
    condition = alltrue([
      for field, value in var.access_applications["saml"].saas_app :
      cloudflare_zero_trust_access_application.this["saml"].saas_app[field] == value if value != null
    ])
    error_message = "Every field of a SAML saas_app must reach the application."
  }

  assert {
    condition = alltrue([
      for field, value in var.access_applications["oidc"].saas_app :
      cloudflare_zero_trust_access_application.this["oidc"].saas_app[field] == value if value != null
    ])
    error_message = "Every field of an OIDC saas_app must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["saml"].scim_config == var.access_applications["saml"].scim_config &&
      cloudflare_zero_trust_access_application.this["oidc"].scim_config == var.access_applications["oidc"].scim_config &&
      cloudflare_zero_trust_access_application.this["bearer"].scim_config == var.access_applications["bearer"].scim_config
    )
    error_message = "Every field of scim_config, secrets included, must reach the application."
  }

  assert {
    condition = (
      nonsensitive(output.access_application_saas_apps["saml"].sp_entity_id) == "https://saas.example.com" &&
      nonsensitive(output.access_application_saas_apps["oidc"].auth_type) == "oidc"
    )
    error_message = "access_application_saas_apps must give the saas_app of each application, by key."
  }
}

run "app_launcher" {
  command = plan

  variables {
    access_applications = {
      launcher = {
        type                  = "app_launcher"
        app_launcher_logo_url = "https://example.com/launcher.svg"
        bg_color              = "#000000"
        header_bg_color       = "#ffffff"
        footer_links          = [{ name = "Support", url = "https://example.com/support" }]
        landing_page_design = {
          button_color      = "#0051c3"
          button_text_color = "#ffffff"
          image_url         = "https://example.com/landing.svg"
          message           = "Sign in with your company account."
          title             = "Example"
        }
        skip_app_launcher_login_page = false
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["launcher"].app_launcher_logo_url == "https://example.com/launcher.svg" &&
      cloudflare_zero_trust_access_application.this["launcher"].bg_color == "#000000" &&
      cloudflare_zero_trust_access_application.this["launcher"].header_bg_color == "#ffffff" &&
      cloudflare_zero_trust_access_application.this["launcher"].skip_app_launcher_login_page == false
    )
    error_message = "app_launcher_logo_url, bg_color, header_bg_color and skip_app_launcher_login_page must reach the application."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["launcher"].footer_links == var.access_applications["launcher"].footer_links &&
      cloudflare_zero_trust_access_application.this["launcher"].landing_page_design == var.access_applications["launcher"].landing_page_design
    )
    error_message = "Every field of footer_links and landing_page_design must reach the application."
  }
}

# target_criteria in the rule format of provider 5.28, and in the legacy
# format of a single target_attributes map.
run "infrastructure" {
  command = plan

  variables {
    access_applications = {
      rules = {
        name = "Rules"
        type = "infrastructure"
        target_criteria = [{
          port     = 22
          protocol = "SSH"
          include  = { tags = { env = ["prod", "staging"] } }
          require  = { target_attributes = { hostname = ["db-1", "db-2"] } }
          exclude  = { tags = { role = ["bastion"] } }
        }]
        # The API takes only policies written inside an infrastructure
        # application, with fewer selectors: no Access group.
        policies = [{
          name       = "SRE"
          decision   = "allow"
          precedence = 1
          include    = [{ email_domain = { domain = "example.com" } }, { email = { email = "sre@example.com" } }]
          exclude    = [{ geo = { country_code = "KP" } }]
          require    = [{ auth_method = { auth_method = "hwk" } }]
          connection_rules = {
            ssh = { usernames = ["root", "ubuntu"], allow_email_alias = true }
          }
          mfa_config = {
            allowed_authenticators = ["security_key"]
            mfa_disabled           = false
            session_duration       = "1h"
          }
        }]
      }
      legacy = {
        name            = "Legacy"
        type            = "infrastructure"
        target_criteria = [{ port = 22, protocol = "SSH", target_attributes = { hostname = ["db-1"] } }]
        policies = [{
          name             = "SRE"
          decision         = "allow"
          include          = [{ email = { email = "sre@example.com" } }]
          connection_rules = { ssh = { usernames = ["root"] } }
        }]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["rules"].target_criteria == var.access_applications["rules"].target_criteria &&
      cloudflare_zero_trust_access_application.this["legacy"].target_criteria == var.access_applications["legacy"].target_criteria
    )
    error_message = "Every field of target_criteria must reach the application, in either format."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_application.this["rules"].policies == var.access_applications["rules"].policies &&
      cloudflare_zero_trust_access_application.this["legacy"].policies[0].id == null &&
      cloudflare_zero_trust_access_application.this["legacy"].policies[0].include == var.access_applications["legacy"].policies[0].include
    )
    error_message = "Every field of a policy written in the application must reach it."
  }
}
