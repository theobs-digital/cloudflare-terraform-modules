mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_tunnel_warp_connector" {
    defaults = {
      id = "5b7d9f1a-3c5e-4a7b-9d1f-3a5c7e9b1d3f"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  tunnel_warp_connectors = {
    office = { name = "office", ha = true }
  }
}

run "no_configs" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_warp_connector_config.this) == 0
    error_message = "Without HA configurations, the module must not create any."
  }
}

run "warp_connector" {}

# The caller takes tunnel_id from tunnel_warp_connector_ids, here through the
# previous run. The other IDs stand for connectors created elsewhere.
run "configs" {
  command = plan

  variables {
    tunnel_warp_connector_configs = {
      local = {
        tunnel_id = run.warp_connector.tunnel_warp_connector_ids["office"]
        ha_mode   = "local"
        config = {
          vips          = [{ address = "10.0.0.10" }, { address = "fd00::10" }]
          vips_previous = [{ address = "10.0.0.9" }]
        }
      }
      aws = {
        tunnel_id = "e1c3a5f7-9b2d-4f6a-8c0e-2d4f6a8c0e1b"
        ha_mode   = "aws"
        config    = { fnr_id = "eni-0123456789abcdef0" }
      }
      disabled = {
        tunnel_id = "9c1e3a5b-7d9f-4b1d-8f3a-5c7e9b1d3f5a"
        ha_mode   = "disabled"
      }
    }
  }

  assert {
    condition     = alltrue([for config in cloudflare_zero_trust_tunnel_warp_connector_config.this : config.account_id == var.account_id])
    error_message = "Every HA configuration must belong to account_id."
  }

  assert {
    condition = (
      cloudflare_zero_trust_tunnel_warp_connector_config.this["local"].tunnel_id == "5b7d9f1a-3c5e-4a7b-9d1f-3a5c7e9b1d3f" &&
      cloudflare_zero_trust_tunnel_warp_connector_config.this["aws"].tunnel_id == "e1c3a5f7-9b2d-4f6a-8c0e-2d4f6a8c0e1b"
    )
    error_message = "tunnel_id must reach the HA configuration, whether the connector comes from the module or elsewhere."
  }

  assert {
    condition = (
      cloudflare_zero_trust_tunnel_warp_connector_config.this["local"].ha_mode == "local" &&
      cloudflare_zero_trust_tunnel_warp_connector_config.this["aws"].ha_mode == "aws" &&
      cloudflare_zero_trust_tunnel_warp_connector_config.this["disabled"].ha_mode == "disabled"
    )
    error_message = "ha_mode must reach the HA configuration."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector_config.this["local"].config == var.tunnel_warp_connector_configs["local"].config
    error_message = "vips and vips_previous must reach the HA configuration, in order."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector_config.this["aws"].config.fnr_id == "eni-0123456789abcdef0" && cloudflare_zero_trust_tunnel_warp_connector_config.this["aws"].config.vips == null
    error_message = "fnr_id must reach the HA configuration, without VIPs."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_warp_connector_config.this["disabled"].config == null
    error_message = "Left out, config must stay unset."
  }
}
