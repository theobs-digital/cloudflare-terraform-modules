# Real API, not a mock: apply this configuration, plan it again, which must
# show no change, and destroy it. Every object is named tf-test-ci-*, and
# routes use 10.252.0.0/16 and fd00:252::/48; the connectivity settings of the
# account are left alone.
#
#   export CLOUDFLARE_API_TOKEN=...
#   export TF_VAR_tunnel_secret="$(openssl rand -base64 32)"
#   terraform init
#   terraform apply -var account_id=... -var zone=example.com
#   terraform plan -detailed-exitcode -var account_id=... -var zone=example.com
#   terraform destroy -var account_id=... -var zone=example.com
provider "cloudflare" {}

locals {
  domain = "tf-test-ci.${var.zone}"
}

module "networks" {
  source = "../"

  account_id = var.account_id

  tunnel_cloudflareds = {
    paris = { name = "tf-test-ci-paris", config_src = "cloudflare" }
    lyon  = { name = "tf-test-ci-lyon", tunnel_secret = var.tunnel_secret }
  }

  # Every attribute, and false and empty values, which Cloudflare returns as written.
  tunnel_cloudflared_configs = {
    paris = {
      tunnel_id = module.networks.tunnel_cloudflared_ids["paris"]
      config = {
        origin_request = {
          access                   = { aud_tag = ["8b4e2f6a1c3d5e7f9a0b2c4d6e8f0a1b3c5d7e9f1a2b4c6d8e0f2a4b6c8d0e2f"], team_name = "tf-test-ci", required = false }
          ca_pool                  = "/etc/ssl/certs/ca-certificates.crt"
          connect_timeout          = 10
          disable_chunked_encoding = false
          http2_origin             = false
          http_host_header         = "app.internal"
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          match_sn_ito_host        = false
          no_happy_eyeballs        = false
          no_tls_verify            = false
          origin_server_name       = "app.internal"
          proxy_type               = ""
          tcp_keep_alive           = 30
          tls_timeout              = 5
        }
        ingress = [
          {
            hostname = "app.${local.domain}"
            path     = "^/api/"
            service  = "https://localhost:8443"
            origin_request = {
              access                   = { aud_tag = ["1f3e5d7c9b0a2f4e6d8c0b1a3f5e7d9c2b4a6f8e0d1c3b5a7f9e2d4c6b8a0f1e"], team_name = "tf-test-ci", required = true }
              ca_pool                  = "/etc/cloudflared/internal-ca.pem"
              connect_timeout          = 5
              disable_chunked_encoding = true
              http2_origin             = true
              http_host_header         = "api.internal"
              keep_alive_connections   = 10
              keep_alive_timeout       = 30
              match_sn_ito_host        = true
              no_happy_eyeballs        = true
              no_tls_verify            = true
              origin_server_name       = "api.internal"
              proxy_type               = "socks"
              tcp_keep_alive           = 15
              tls_timeout              = 3
            }
          },
          { hostname = "app.${local.domain}", service = "http://localhost:8080" },
          { hostname = "ssh.${local.domain}", service = "ssh://localhost:22" },
          { service = "http_status:404" },
        ]
      }
    }
  }

  tunnel_cloudflared_virtual_networks = {
    prod    = { name = "tf-test-ci-prod", comment = "tf-test-ci" }
    staging = { name = "tf-test-ci-staging" }
  }

  tunnel_cloudflared_routes = {
    paris = {
      network            = "10.252.1.0/24"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["paris"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["prod"]
      comment            = "tf-test-ci"
    }
    paris_v6 = {
      network            = "fd00:252:1::/64"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["paris"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["prod"]
    }
    lyon_staging = {
      network            = "10.252.1.0/24"
      tunnel_id          = module.networks.tunnel_cloudflared_ids["lyon"]
      virtual_network_id = module.networks.tunnel_cloudflared_virtual_network_ids["staging"]
      comment            = "tf-test-ci"
    }
    # To a WARP Connector, in the default virtual network.
    office = {
      network   = "10.252.2.0/24"
      tunnel_id = module.networks.tunnel_warp_connector_ids["office"]
      comment   = "tf-test-ci"
    }
  }

  network_hostname_routes = {
    intranet = {
      hostname  = "intranet.${local.domain}"
      tunnel_id = module.networks.tunnel_cloudflared_ids["paris"]
      comment   = "tf-test-ci"
    }
    mesh = {
      hostname  = "mesh.${local.domain}"
      tunnel_id = module.networks.tunnel_warp_connector_ids["office"]
      comment   = ""
    }
  }

  tunnel_warp_connectors = {
    office     = { name = "tf-test-ci-office" }
    datacenter = { name = "tf-test-ci-datacenter", ha = true }
  }

  tunnel_warp_connector_configs = {
    datacenter = {
      tunnel_id = module.networks.tunnel_warp_connector_ids["datacenter"]
      ha_mode   = "local"
      config    = { vips = [{ address = "10.252.3.10" }, { address = "fd00:252:3::10" }] }
    }
  }
}
