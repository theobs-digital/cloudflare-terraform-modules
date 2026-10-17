# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "networks" {
  source = "../.."

  account_id = var.account_id

  tunnel_cloudflareds = {
    office = { name = "office", config_src = "cloudflare" }
  }

  tunnel_cloudflared_configs = {
    office = {
      tunnel_id = module.networks.tunnel_cloudflared_ids["office"]
      config = {
        ingress = [
          { hostname = "wiki.example.com", service = "http://localhost:8080" },
          # The last rule takes every other request.
          { service = "http_status:404" },
        ]
      }
    }
  }

  # In the default virtual network: devices with the Cloudflare One Client reach the LAN.
  tunnel_cloudflared_routes = {
    office_lan = {
      network   = "192.168.1.0/24"
      tunnel_id = module.networks.tunnel_cloudflared_ids["office"]
    }
  }
}
