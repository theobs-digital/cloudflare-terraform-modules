mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_ai_controls_mcp_server" {
    defaults = {
      # Settings unlike the ones the tests give, which must win.
      is_shared_oauth_callback_enabled = false
      secure_web_gateway               = false
    }
  }

  mock_resource "cloudflare_zero_trust_access_ai_controls_mcp_portal" {
    defaults = {
      # Settings unlike the ones the tests give, which must win.
      code_mode          = "off"
      secure_web_gateway = false
      servers            = [{ server_id = "computed", default_disabled = false, on_behalf = true }]
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_mcp" {
  command = plan

  assert {
    condition = (
      length(cloudflare_zero_trust_access_ai_controls_mcp_server.this) == 0 &&
      length(cloudflare_zero_trust_access_ai_controls_mcp_portal.this) == 0
    )
    error_message = "Without access_ai_controls_mcp_servers and access_ai_controls_mcp_portals, the module must create neither."
  }
}

run "mcp_minimal" {
  command = plan

  variables {
    access_ai_controls_mcp_servers = {
      docs = {
        id        = "docs"
        name      = "Docs"
        hostname  = "https://docs.mcp.example.com/mcp"
        auth_type = "unauthenticated"
      }
    }
    access_ai_controls_mcp_portals = {
      main = {
        id       = "main"
        name     = "Main"
        hostname = "mcp.example.com"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].account_id == var.account_id &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].id == "docs" &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].name == "Docs" &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].hostname == "https://docs.mcp.example.com/mcp" &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].auth_type == "unauthenticated"
    )
    error_message = "The MCP server must belong to account_id, with id, name, hostname and auth_type as given."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].auth_credentials == null &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].client_secret == null &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["docs"].updated_tools == null
    )
    error_message = "Attributes of the MCP server left out must stay unset."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].account_id == var.account_id &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].id == "main" &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].name == "Main" &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].hostname == "mcp.example.com" &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].description == null
    )
    error_message = "The MCP portal must belong to account_id, with id, name and hostname as given."
  }
}

run "mcp" {
  variables {
    access_ai_controls_mcp_servers = {
      wiki = {
        id               = "wiki"
        name             = "Wiki"
        hostname         = "https://wiki.example.com/mcp"
        auth_type        = "oauth"
        description      = "Internal wiki"
        auth_credentials = "{\"auth_mode\":\"manual\",\"config\":{\"authorization_endpoint\":\"https://auth.example.com/authorize\",\"token_endpoint\":\"https://auth.example.com/token\"},\"registration_info\":{\"client_id\":\"wiki\"}}"
        client_secret    = "example-secret"

        is_shared_oauth_callback_enabled = true
        secure_web_gateway               = true

        updated_prompts = [{ name = "summarize", alias = "digest", description = "Digest a page", enabled = true }]
        updated_tools   = [{ name = "delete_page", enabled = false }]
      }
    }
    access_ai_controls_mcp_portals = {
      main = {
        id                 = "main"
        name               = "Main"
        hostname           = "mcp.example.com"
        code_mode          = "enforced"
        description        = "Every MCP server"
        secure_web_gateway = true
        servers = [{
          server_id        = "wiki"
          default_disabled = true
          on_behalf        = false
          updated_prompts  = [{ name = "summarize", enabled = false }]
          updated_tools    = [{ name = "search", alias = "find", description = "Find a page" }]
        }]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].description == "Internal wiki" &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].auth_credentials == var.access_ai_controls_mcp_servers["wiki"].auth_credentials &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].client_secret == "example-secret" &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].is_shared_oauth_callback_enabled == true &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].secure_web_gateway == true
    )
    error_message = "description, auth_credentials, client_secret, is_shared_oauth_callback_enabled and secure_web_gateway must reach the MCP server."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].updated_prompts == var.access_ai_controls_mcp_servers["wiki"].updated_prompts &&
      cloudflare_zero_trust_access_ai_controls_mcp_server.this["wiki"].updated_tools == var.access_ai_controls_mcp_servers["wiki"].updated_tools
    )
    error_message = "updated_prompts and updated_tools must reach the MCP server."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].code_mode == "enforced" &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].description == "Every MCP server" &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].secure_web_gateway == true &&
      cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"].servers == var.access_ai_controls_mcp_portals["main"].servers
    )
    error_message = "code_mode, description, secure_web_gateway and servers must reach the MCP portal."
  }

  assert {
    condition     = output.access_ai_controls_mcp_server_ids == { wiki = "wiki" }
    error_message = "access_ai_controls_mcp_server_ids must give the ID of each MCP server."
  }
}
