# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "access" {
  source = "../.."

  account_id = var.account_id

  # Import the organization before the first apply: see the README.
  organization = {
    name                                        = "example.cloudflareaccess.com"
    auth_domain                                 = "example.cloudflareaccess.com"
    session_duration                            = "24h"
    auto_redirect_to_identity                   = false
    deny_unmatched_requests                     = false
    deny_unmatched_requests_exempted_zone_names = []
    login_design = {
      background_color = "#1e293b"
      text_color       = "#ffffff"
      header_text      = "Example"
      footer_text      = "For Example staff only"
      logo_path        = "https://www.example.com/logo.png"
    }
    custom_pages = {
      identity_denied = module.access.access_custom_page_ids["identity_denied"]
      forbidden       = module.access.access_custom_page_ids["forbidden"]
    }
  }

  access_identity_providers = {
    otp = { name = "One-time PIN", type = "onetimepin", config = {} }
    entra = {
      name = "Microsoft Entra ID"
      type = "azureAD"
      config = {
        client_id      = "4f2b7c1e-9d3a-4e8b-a6c5-1b2d3e4f5a6b"
        client_secret  = var.entra_client_secret
        directory_id   = "9b2a1c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
        support_groups = true
      }
      # Then give Entra ID the scim_base_url and secret of the output.
      scim_config = { enabled = true, user_deprovision = true, seat_deprovision = true }
    }
  }

  access_groups = {
    staff = {
      name    = "Staff"
      include = [{ email_domain = { domain = "example.com" } }]
      require = [{ login_method = { id = module.access.access_identity_provider_ids["entra"] } }]
    }
    contractors = {
      name = "Contractors"
      include = [
        { email = { email = "alice@example.net" } },
        { email = { email = "bob@example.net" } },
      ]
    }
  }

  access_policies = {
    staff = {
      name             = "Staff"
      decision         = "allow"
      include          = [{ group = { id = module.access.access_group_ids["staff"] } }]
      exclude          = [{ geo = { country_code = "KP" } }]
      session_duration = "8h"
    }
    contractors = {
      name                           = "Contractors"
      decision                       = "allow"
      include                        = [{ group = { id = module.access.access_group_ids["contractors"] } }]
      approval_required              = true
      approval_groups                = [{ approvals_needed = 1, email_addresses = ["it@example.com"] }]
      purpose_justification_required = true
      purpose_justification_prompt   = "Ticket number"
      session_duration               = "1h"
    }
    ci = {
      name     = "CI"
      decision = "non_identity"
      include  = [{ service_token = { token_id = module.access.access_service_token_ids["ci"] } }]
    }
  }

  access_applications = {
    wiki = {
      name         = "Wiki"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "wiki.example.com" }]
      policies = [
        { id = module.access.access_policy_ids["staff"], precedence = 1 },
        { id = module.access.access_policy_ids["contractors"], precedence = 2 },
      ]
      allowed_idps              = [module.access.access_identity_provider_ids["entra"]]
      auto_redirect_to_identity = true
      app_launcher_visible      = true
      session_duration          = "24h"
      tags                      = [module.access.access_tag_ids["engineering"]]
      custom_pages              = [module.access.access_custom_page_ids["identity_denied"]]
    }
    api = {
      name                      = "API"
      type                      = "self_hosted"
      destinations              = [{ type = "public", uri = "api.example.com" }]
      policies                  = [{ id = module.access.access_policy_ids["ci"] }]
      service_auth_401_redirect = true
      cors_headers = {
        allowed_origins   = ["https://wiki.example.com"]
        allowed_methods   = ["GET", "POST"]
        allow_credentials = true
        max_age           = 600
      }
    }
    ssh = {
      name         = "SSH"
      type         = "ssh"
      destinations = [{ type = "public", uri = "ssh.example.com" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
    crm = {
      name = "CRM"
      type = "saas"
      saas_app = {
        auth_type     = "oidc"
        redirect_uris = ["https://crm.example.net/oauth/callback"]
        grant_types   = ["authorization_code"]
        scopes        = ["openid", "email", "profile"]
      }
      policies = [{ id = module.access.access_policy_ids["staff"] }]
    }
    # Policies written inside, with fewer selectors: no Access group.
    databases = {
      name = "Databases"
      type = "infrastructure"
      target_criteria = [{
        port     = 22
        protocol = "SSH"
        include  = { tags = { environment = ["production"] } }
      }]
      policies = [{
        name             = "Staff"
        decision         = "allow"
        include          = [{ email_domain = { domain = "example.com" } }]
        connection_rules = { ssh = { usernames = ["ubuntu"] } }
      }]
    }
    # The API creates no application for an MCP portal or server.
    mcp = {
      name         = "MCP"
      type         = "mcp_portal"
      destinations = [{ type = "public", uri = "mcp.example.com" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
    mcp_docs = {
      name         = "Cloudflare docs"
      type         = "mcp"
      destinations = [{ type = "via_mcp_server_portal", mcp_server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
  }

  access_service_tokens = {
    ci = { name = "CI", duration = "8760h" }
  }

  access_mtls_certificates = {
    corporate = {
      name                 = "Corporate CA"
      certificate          = var.client_ca_certificate
      associated_hostnames = ["api.example.com"]
    }
  }

  # Replaces the whole list of the account.
  access_mtls_hostname_settings = {
    settings = [{ hostname = "api.example.com", china_network = false, client_certificate_forwarding = true }]
  }

  access_short_lived_certificates = {
    ssh = { app_id = module.access.access_application_ids["ssh"] }
  }

  access_tags = {
    engineering = { name = "Engineering" }
  }

  access_custom_pages = {
    identity_denied = {
      name        = "Identity denied"
      type        = "identity_denied"
      custom_html = "<html><body><h1>Access denied</h1><p>Ask the IT team for access.</p></body></html>"
    }
    forbidden = {
      name        = "Forbidden"
      type        = "forbidden"
      custom_html = "<html><body><h1>Forbidden</h1><p>This device or location is not allowed.</p></body></html>"
    }
  }

  access_key_configuration = { key_rotation_interval_days = 90 }

  access_infrastructure_targets = {
    db1 = {
      hostname = "db-1"
      ip       = { ipv4 = { ip_addr = "10.0.0.11" } }
      tags     = { environment = "production" }
    }
    db2 = {
      hostname = "db-2"
      ip       = { ipv4 = { ip_addr = "10.0.0.12" } }
      tags     = { environment = "production" }
    }
  }

  access_ai_controls_mcp_servers = {
    docs = {
      id        = "docs"
      name      = "Cloudflare docs"
      hostname  = "https://docs.mcp.cloudflare.com/mcp"
      auth_type = "unauthenticated"
    }
  }

  access_ai_controls_mcp_portals = {
    main = {
      id       = "main"
      name     = "MCP"
      hostname = "mcp.example.com"
      servers  = [{ server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
    }
  }
}
