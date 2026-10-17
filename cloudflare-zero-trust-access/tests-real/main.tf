# Real API, not a mock: the Real API tests workflow applies this configuration,
# plans it again, which must show no change, and destroys it. Every object is
# named tf-test-ci-*; the settings of the account are left alone.
#
#   export CLOUDFLARE_API_TOKEN=...
#   terraform init
#   terraform apply -var account_id=... -var zone=example.com
#   terraform plan -detailed-exitcode -var account_id=... -var zone=example.com
#   terraform destroy -var account_id=... -var zone=example.com
provider "cloudflare" {}

locals {
  domain = "tf-test-ci.${var.zone}"
}

module "access" {
  source = "../"

  account_id = var.account_id

  access_identity_providers = {
    entra = {
      name = "tf-test-ci-entra"
      type = "azureAD"
      config = {
        client_id      = "4f2b7c1e-9d3a-4e8b-a6c5-1b2d3e4f5a6b"
        client_secret  = var.entra_client_secret
        directory_id   = "9b2a1c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
        support_groups = true
      }
      scim_config = { enabled = true, user_deprovision = true, seat_deprovision = true }
    }
  }

  access_groups = {
    staff = {
      name    = "tf-test-ci-staff"
      include = [{ email_domain = { domain = "example.com" } }]
      require = [{ login_method = { id = module.access.access_identity_provider_ids["entra"] } }]
    }
    contractors = {
      name = "tf-test-ci-contractors"
      include = [
        { email = { email = "alice@example.net" } },
        { email = { email = "bob@example.net" } },
      ]
    }
  }

  access_policies = {
    staff = {
      name             = "tf-test-ci-staff"
      decision         = "allow"
      include          = [{ group = { id = module.access.access_group_ids["staff"] } }]
      exclude          = [{ geo = { country_code = "KP" } }]
      session_duration = "8h"
    }
    contractors = {
      name                           = "tf-test-ci-contractors"
      decision                       = "allow"
      include                        = [{ group = { id = module.access.access_group_ids["contractors"] } }]
      approval_required              = true
      approval_groups                = [{ approvals_needed = 1, email_addresses = ["it@example.com"] }]
      purpose_justification_required = true
      purpose_justification_prompt   = "Ticket number"
      session_duration               = "1h"
    }
    ci = {
      name     = "tf-test-ci-service"
      decision = "non_identity"
      include  = [{ service_token = { token_id = module.access.access_service_token_ids["ci"] } }]
    }
  }

  access_applications = {
    wiki = {
      name         = "tf-test-ci-wiki"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "wiki.${local.domain}" }]
      policies = [
        { id = module.access.access_policy_ids["staff"], precedence = 1 },
        { id = module.access.access_policy_ids["contractors"], precedence = 2 },
      ]
      allowed_idps              = [module.access.access_identity_provider_ids["entra"]]
      auto_redirect_to_identity = true
      app_launcher_visible      = true
      session_duration          = "24h"
      tags                      = [module.access.access_tag_ids["engineering"]]
    }
    api = {
      name                      = "tf-test-ci-api"
      type                      = "self_hosted"
      destinations              = [{ type = "public", uri = "api.${local.domain}" }]
      policies                  = [{ id = module.access.access_policy_ids["ci"] }]
      service_auth_401_redirect = true
      cors_headers = {
        allowed_origins   = ["https://wiki.${local.domain}"]
        allowed_methods   = ["GET", "POST"]
        allow_credentials = true
        max_age           = 600
      }
    }
    ssh = {
      name         = "tf-test-ci-ssh"
      type         = "ssh"
      destinations = [{ type = "public", uri = "ssh.${local.domain}" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
    crm = {
      name = "tf-test-ci-crm"
      type = "saas"
      saas_app = {
        auth_type     = "oidc"
        redirect_uris = ["https://crm.${local.domain}/oauth/callback"]
        grant_types   = ["authorization_code"]
        scopes        = ["openid", "email", "profile"]
      }
      policies = [{ id = module.access.access_policy_ids["staff"] }]
    }
    databases = {
      name = "tf-test-ci-databases"
      type = "infrastructure"
      target_criteria = [{
        port     = 22
        protocol = "SSH"
        include  = { tags = { environment = ["tf-test-ci"] } }
      }]
      policies = [{
        name             = "tf-test-ci-staff"
        decision         = "allow"
        include          = [{ email_domain = { domain = "example.com" } }]
        connection_rules = { ssh = { usernames = ["ubuntu"] } }
      }]
    }
    mcp = {
      name         = "tf-test-ci-mcp"
      type         = "mcp_portal"
      destinations = [{ type = "public", uri = "mcp.${local.domain}" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
    mcp_docs = {
      name         = "tf-test-ci-mcp-docs"
      type         = "mcp"
      destinations = [{ type = "via_mcp_server_portal", mcp_server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
  }

  access_service_tokens = {
    ci = { name = "tf-test-ci-service", duration = "8760h" }
  }

  access_short_lived_certificates = {
    ssh = { app_id = module.access.access_application_ids["ssh"] }
  }

  access_tags = {
    engineering = { name = "tf-test-ci-engineering" }
  }

  # An address no tunnel route covers, which Cloudflare accepts.
  access_infrastructure_targets = {
    db1 = {
      hostname = "tf-test-ci-db-1"
      ip       = { ipv4 = { ip_addr = "10.255.253.11" } }
      tags     = { environment = "tf-test-ci" }
    }
    db2 = {
      hostname = "tf-test-ci-db-2"
      ip       = { ipv4 = { ip_addr = "10.255.253.12" } }
      tags     = { environment = "tf-test-ci" }
    }
  }

  access_ai_controls_mcp_servers = {
    docs = {
      id        = "tf-test-ci-docs"
      name      = "tf-test-ci-docs"
      hostname  = "https://docs.mcp.cloudflare.com/mcp"
      auth_type = "unauthenticated"
    }
  }

  access_ai_controls_mcp_portals = {
    main = {
      id       = "tf-test-ci-main"
      name     = "tf-test-ci-main"
      hostname = "mcp.${local.domain}"
      servers  = [{ server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
    }
  }
}
