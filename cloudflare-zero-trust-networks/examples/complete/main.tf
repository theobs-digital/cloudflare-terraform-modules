# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "networks" {
  source = "../.."

  account_id = var.account_id

  tunnel_cloudflareds = {
    # Configured from Cloudflare, by tunnel_cloudflared_configs below.
    paris = { name = "paris", config_src = "cloudflare" }
    # Configured by the cloudflared configuration file on the host.
    lyon = { name = "lyon", tunnel_secret = var.lyon_tunnel_secret }
  }

  tunnel_cloudflared_configs = {
    paris = {
      tunnel_id = module.networks.tunnel_cloudflared_ids["paris"]
      config = {
        # What every rule inherits, unless the rule sets its own. Timeouts in seconds.
        origin_request = {
          connect_timeout        = 10
          tls_timeout            = 5
          tcp_keep_alive         = 30
          keep_alive_timeout     = 90
          keep_alive_connections = 100
          no_happy_eyeballs      = false
        }
        ingress = [
          {
            hostname = "app.example.com"
            path     = "^/api/"
            service  = "https://localhost:8443"
            origin_request = {
              origin_server_name = "api.internal"
              ca_pool            = "/etc/cloudflared/internal-ca.pem"
              http2_origin       = true
              # cloudflared refuses requests without a valid Access token.
              access = { required = true, team_name = "example", aud_tag = [var.api_aud] }
            }
          },
          { hostname = "app.example.com", service = "http://localhost:8080" },
          { hostname = "ssh.example.com", service = "ssh://localhost:22" },
          { service = "http_status:404" },
        ]
      }
    }
  }

  tunnel_cloudflared_virtual_networks = {
    prod    = { name = "prod", comment = "Production sites" }
    staging = { name = "staging", comment = "Staging, with the same CIDRs as production" }
  }

  tunnel_cloudflared_routes = {
    paris = {
      network            = "10.1.0.0/16"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["paris"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["prod"]
      comment            = "Paris LAN"
    }
    paris_v6 = {
      network            = "fd00:1::/64"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["paris"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["prod"]
    }
    # The same CIDR, in another virtual network.
    lyon_staging = {
      network            = "10.1.0.0/16"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["lyon"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["staging"]
      comment            = "Staging, in Lyon"
    }
    # To a WARP Connector, in the default virtual network.
    office = {
      network   = "192.168.1.0/24"
      tunnel_id = module.networks.tunnel_warp_connector_ids["office"]
      comment   = "Office LAN"
    }
  }

  network_hostname_routes = {
    intranet = {
      hostname  = "intranet.corp.example.com"
      tunnel_id = module.networks.tunnel_cloudflared_ids["paris"]
      comment   = "Private hostname, resolved by the Paris network"
    }
  }

  tunnel_warp_connectors = {
    office = { name = "office" }
    # Two hosts on one subnet run it with the same token; ha is set at creation only.
    datacenter = { name = "datacenter", ha = true }
  }

  tunnel_warp_connector_configs = {
    datacenter = {
      tunnel_id = module.networks.tunnel_warp_connector_ids["datacenter"]
      ha_mode   = "local"
      # The active host takes the virtual IP.
      config = { vips = [{ address = "10.3.0.10" }] }
    }
  }

  # Settings of the whole account. Import them before the first apply: see the README.
  connectivity_settings = {
    icmp_proxy_enabled   = true
    offramp_warp_enabled = false
  }
}
