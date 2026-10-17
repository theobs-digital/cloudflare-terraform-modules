mock_provider "cloudflare" {}

# Computed values that differ from every input: a value the module fails to
# pass shows up here. An override replaces the defaults of mock_resource.
override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["prod"]
  values = {
    id                 = "3e2c8b1a-6d4f-4a9e-8c7b-2f1e0d9c8b7a"
    comment            = "Set by Cloudflare"
    is_default_network = true
  }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["staging"]
  values = {
    id = "9a8b7c6d-5e4f-4321-8fed-cba987654321"
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_virtual_networks" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this) == 0 && output.tunnel_cloudflared_virtual_network_ids == {}
    error_message = "Without virtual networks, the module must not create any, and tunnel_cloudflared_virtual_network_ids must be empty."
  }
}

run "virtual_networks" {
  variables {
    tunnel_cloudflared_virtual_networks = {
      prod    = { name = "prod" }
      staging = { name = "staging", comment = "Staging sites", is_default_network = false }
    }
  }

  assert {
    condition     = alltrue([for network in cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this : network.account_id == var.account_id])
    error_message = "Every virtual network must belong to account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["prod"].name == "prod" && cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["staging"].name == "staging"
    error_message = "name must reach the virtual network."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["prod"].comment == "Set by Cloudflare" && cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["prod"].is_default_network == true
    error_message = "Left out, comment and is_default_network must stay unset, for the provider defaults."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["staging"].comment == "Staging sites" && cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this["staging"].is_default_network == false
    error_message = "comment and is_default_network must reach the virtual network."
  }

  assert {
    condition = output.tunnel_cloudflared_virtual_network_ids == {
      prod    = "3e2c8b1a-6d4f-4a9e-8c7b-2f1e0d9c8b7a"
      staging = "9a8b7c6d-5e4f-4321-8fed-cba987654321"
    }
    error_message = "tunnel_cloudflared_virtual_network_ids must give the ID of each virtual network, by key."
  }
}
