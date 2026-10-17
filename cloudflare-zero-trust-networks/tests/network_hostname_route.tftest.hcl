mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_tunnel_cloudflared" {
    defaults = {
      id = "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
    }
  }
}

override_resource {
  target = cloudflare_zero_trust_network_hostname_route.this["wiki"]
  values = {
    id = "2a4c6e8f-0b1d-4f3a-9c5e-7a9b1d3f5e7c"
  }
}

override_resource {
  target = cloudflare_zero_trust_network_hostname_route.this["git"]
  values = {
    id = "8e0f2a4c-6b8d-4e1f-a3c5-e7f9a1b3d5c7"
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  tunnel_cloudflareds = {
    site_a = { name = "site-a" }
  }
}

run "no_hostname_routes" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_network_hostname_route.this) == 0 && output.network_hostname_route_ids == {}
    error_message = "Without hostname routes, the module must not create any, and network_hostname_route_ids must be empty."
  }
}

run "tunnel" {}

# The caller takes tunnel_id from tunnel_cloudflared_ids, here through the
# previous run.
run "hostname_routes" {
  variables {
    network_hostname_routes = {
      wiki = {
        hostname  = "wiki.internal.example"
        tunnel_id = run.tunnel.tunnel_cloudflared_ids["site_a"]
      }
      git = {
        hostname  = "git.internal.example"
        tunnel_id = run.tunnel.tunnel_cloudflared_ids["site_a"]
        comment   = "Git server"
      }
    }
  }

  assert {
    condition     = alltrue([for route in cloudflare_zero_trust_network_hostname_route.this : route.account_id == var.account_id && route.tunnel_id == "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"])
    error_message = "Every hostname route must target tunnel_id, in account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_network_hostname_route.this["wiki"].hostname == "wiki.internal.example" && cloudflare_zero_trust_network_hostname_route.this["git"].hostname == "git.internal.example"
    error_message = "hostname must reach the hostname route."
  }

  assert {
    condition     = cloudflare_zero_trust_network_hostname_route.this["wiki"].comment == null && cloudflare_zero_trust_network_hostname_route.this["git"].comment == "Git server"
    error_message = "comment must reach the hostname route, and stay unset when left out."
  }

  assert {
    condition = output.network_hostname_route_ids == {
      wiki = "2a4c6e8f-0b1d-4f3a-9c5e-7a9b1d3f5e7c"
      git  = "8e0f2a4c-6b8d-4e1f-a3c5-e7f9a1b3d5c7"
    }
    error_message = "network_hostname_route_ids must give the ID of each hostname route, by key."
  }
}
