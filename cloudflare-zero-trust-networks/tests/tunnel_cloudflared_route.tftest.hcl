mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_tunnel_cloudflared" {
    defaults = {
      id = "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
    }
  }

  mock_resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" {
    defaults = {
      id = "3e2c8b1a-6d4f-4a9e-8c7b-2f1e0d9c8b7a"
    }
  }
}

# Computed values that differ from every input: a value the module fails to
# pass shows up here. An override replaces the defaults of mock_resource.
override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared_route.this["lan"]
  values = {
    id                 = "0c5e3f7a-2b9d-4e8f-a1c3-5d7e9f0a2b4c"
    comment            = "Set by Cloudflare"
    virtual_network_id = "6b0a6655-1631-4d7b-a8c7-44ebccfccdb1"
  }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared_route.this["lan_v6"]
  values = {
    id = "7d1f3a5c-9e2b-4c6d-8f0a-1b3c5d7e9f2a"
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  tunnel_cloudflareds = {
    site_a = { name = "site-a" }
  }
  tunnel_cloudflared_virtual_networks = {
    prod = { name = "prod" }
  }
}

run "no_routes" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared_route.this) == 0 && output.tunnel_cloudflared_route_ids == {}
    error_message = "Without routes, the module must not create any, and tunnel_cloudflared_route_ids must be empty."
  }
}

run "networks" {}

# The caller takes tunnel_id and virtual_network_id from the outputs of the
# module, here through the previous run.
run "routes" {
  variables {
    tunnel_cloudflared_routes = {
      lan = {
        network   = "10.0.0.0/24"
        tunnel_id = run.networks.tunnel_cloudflared_ids["site_a"]
      }
      lan_v6 = {
        network            = "fd00:10::/64"
        tunnel_id          = run.networks.tunnel_cloudflared_ids["site_a"]
        virtual_network_id = run.networks.tunnel_cloudflared_virtual_network_ids["prod"]
        comment            = "Site A, IPv6"
      }
    }
  }

  assert {
    condition     = alltrue([for route in cloudflare_zero_trust_tunnel_cloudflared_route.this : route.account_id == var.account_id && route.tunnel_id == "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"])
    error_message = "Every route must target tunnel_id, in account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_route.this["lan"].network == "10.0.0.0/24" && cloudflare_zero_trust_tunnel_cloudflared_route.this["lan_v6"].network == "fd00:10::/64"
    error_message = "network must reach the route."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_route.this["lan"].virtual_network_id == "6b0a6655-1631-4d7b-a8c7-44ebccfccdb1" && cloudflare_zero_trust_tunnel_cloudflared_route.this["lan"].comment == "Set by Cloudflare"
    error_message = "Left out, virtual_network_id and comment must stay unset, for Cloudflare to choose them."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_route.this["lan_v6"].virtual_network_id == "3e2c8b1a-6d4f-4a9e-8c7b-2f1e0d9c8b7a" && cloudflare_zero_trust_tunnel_cloudflared_route.this["lan_v6"].comment == "Site A, IPv6"
    error_message = "virtual_network_id and comment must reach the route."
  }

  assert {
    condition = output.tunnel_cloudflared_route_ids == {
      lan    = "0c5e3f7a-2b9d-4e8f-a1c3-5d7e9f0a2b4c"
      lan_v6 = "7d1f3a5c-9e2b-4c6d-8f0a-1b3c5d7e9f2a"
    }
    error_message = "tunnel_cloudflared_route_ids must give the ID of each route, by key."
  }
}
