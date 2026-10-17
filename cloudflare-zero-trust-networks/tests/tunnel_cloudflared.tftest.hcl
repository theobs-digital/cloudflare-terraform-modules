mock_provider "cloudflare" {
  mock_data "cloudflare_zero_trust_tunnel_cloudflared_token" {
    defaults = {
      token = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
    }
  }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared.this["remote"]
  values = {
    id = "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
  }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared.this["local"]
  values = {
    id = "c3a9d2b1-5e7f-4a60-9b8c-1d2e3f405162"
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_tunnels" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared.this) == 0 && length(data.cloudflare_zero_trust_tunnel_cloudflared_token.this) == 0
    error_message = "Without tunnels, the module must not create any, nor read any token."
  }

  assert {
    condition     = output.tunnel_cloudflared_ids == {} && nonsensitive(output.tunnel_cloudflared_tokens) == {}
    error_message = "Without tunnels, tunnel_cloudflared_ids and tunnel_cloudflared_tokens must be empty."
  }
}

run "tunnels" {
  variables {
    tunnel_cloudflareds = {
      remote = { name = "site-a", config_src = "cloudflare" }
      local  = { name = "site-b", tunnel_secret = "AQIDBAUGBwgBAgMEBQYHCAECAwQFBgcIAQIDBAUGBwg=" }
    }
  }

  assert {
    condition     = alltrue([for tunnel in cloudflare_zero_trust_tunnel_cloudflared.this : tunnel.account_id == var.account_id])
    error_message = "Every tunnel must belong to account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared.this["remote"].name == "site-a" && cloudflare_zero_trust_tunnel_cloudflared.this["remote"].config_src == "cloudflare"
    error_message = "name and config_src must reach the tunnel."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared.this["remote"].tunnel_secret == null
    error_message = "Left out, tunnel_secret must stay unset, for Cloudflare to generate it."
  }

  assert {
    condition     = nonsensitive(cloudflare_zero_trust_tunnel_cloudflared.this["local"].tunnel_secret) == "AQIDBAUGBwgBAgMEBQYHCAECAwQFBgcIAQIDBAUGBwg="
    error_message = "tunnel_secret must reach the tunnel."
  }

  assert {
    condition = output.tunnel_cloudflared_ids == {
      remote = "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
      local  = "c3a9d2b1-5e7f-4a60-9b8c-1d2e3f405162"
    }
    error_message = "tunnel_cloudflared_ids must give the ID of each tunnel, by key."
  }

  assert {
    condition = alltrue([
      for key, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.this :
      token.account_id == var.account_id && token.tunnel_id == cloudflare_zero_trust_tunnel_cloudflared.this[key].id
    ])
    error_message = "The token of each tunnel must be read from that tunnel, in account_id."
  }

  assert {
    condition = nonsensitive(output.tunnel_cloudflared_tokens) == {
      remote = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
      local  = "eyJhIjoiMDIzZTEwNWY0ZWNlZjhhZDljYTMxYTgzNzJkMGMzNTMifQ=="
    }
    error_message = "tunnel_cloudflared_tokens must give the token of each tunnel, by key."
  }
}
