mock_provider "cloudflare" {
  mock_data "cloudflare_zero_trust_tunnel_warp_connector_token" {
    defaults = {
      token = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
    }
  }
}

# Computed values that differ from every input: a value the module fails to
# pass shows up here. An override replaces the defaults of mock_resource.
override_resource {
  target = cloudflare_zero_trust_tunnel_warp_connector.this["office"]
  values = {
    id = "5b7d9f1a-3c5e-4a7b-9d1f-3a5c7e9b1d3f"
    ha = true
  }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_warp_connector.this["vpc"]
  values = {
    id = "e1c3a5f7-9b2d-4f6a-8c0e-2d4f6a8c0e1b"
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_warp_connectors" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_warp_connector.this) == 0 && length(data.cloudflare_zero_trust_tunnel_warp_connector_token.this) == 0
    error_message = "Without WARP Connectors, the module must not create any, nor read any token."
  }

  assert {
    condition     = output.tunnel_warp_connector_ids == {} && nonsensitive(output.tunnel_warp_connector_tokens) == {}
    error_message = "Without WARP Connectors, tunnel_warp_connector_ids and tunnel_warp_connector_tokens must be empty."
  }
}

run "warp_connectors" {
  variables {
    tunnel_warp_connectors = {
      office = { name = "office" }
      vpc    = { name = "vpc", ha = true, tunnel_secret = "AQIDBAUGBwgBAgMEBQYHCAECAwQFBgcIAQIDBAUGBwg=" }
    }
  }

  assert {
    condition     = alltrue([for connector in cloudflare_zero_trust_tunnel_warp_connector.this : connector.account_id == var.account_id])
    error_message = "Every WARP Connector must belong to account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector.this["office"].name == "office" && cloudflare_zero_trust_tunnel_warp_connector.this["vpc"].name == "vpc"
    error_message = "name must reach the WARP Connector."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector.this["office"].ha == true && cloudflare_zero_trust_tunnel_warp_connector.this["office"].tunnel_secret == null
    error_message = "Left out, ha and tunnel_secret must stay unset, for the provider default and Cloudflare."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector.this["vpc"].ha == true && nonsensitive(cloudflare_zero_trust_tunnel_warp_connector.this["vpc"].tunnel_secret) == "AQIDBAUGBwgBAgMEBQYHCAECAwQFBgcIAQIDBAUGBwg="
    error_message = "ha and tunnel_secret must reach the WARP Connector."
  }

  assert {
    condition = output.tunnel_warp_connector_ids == {
      office = "5b7d9f1a-3c5e-4a7b-9d1f-3a5c7e9b1d3f"
      vpc    = "e1c3a5f7-9b2d-4f6a-8c0e-2d4f6a8c0e1b"
    }
    error_message = "tunnel_warp_connector_ids must give the ID of each WARP Connector, by key."
  }

  assert {
    condition = alltrue([
      for key, token in data.cloudflare_zero_trust_tunnel_warp_connector_token.this :
      token.account_id == var.account_id && token.tunnel_id == cloudflare_zero_trust_tunnel_warp_connector.this[key].id
    ])
    error_message = "The token of each WARP Connector must be read from that connector, in account_id."
  }

  assert {
    condition = nonsensitive(output.tunnel_warp_connector_tokens) == {
      office = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
      vpc    = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
    }
    error_message = "tunnel_warp_connector_tokens must give the token of each WARP Connector, by key."
  }
}
