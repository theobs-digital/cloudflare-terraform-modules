mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_tunnel_cloudflared" {
    defaults = {
      id = "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  tunnel_cloudflareds = {
    site_a = { name = "site-a", config_src = "cloudflare" }
  }
}

run "no_configs" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared_config.this) == 0
    error_message = "Without configurations, the module must not create any."
  }
}

run "tunnel" {}

# The caller takes tunnel_id from tunnel_cloudflared_ids, here through the
# previous run.
run "minimal_config" {
  command = plan

  variables {
    tunnel_cloudflared_configs = {
      site_a = {
        tunnel_id = run.tunnel.tunnel_cloudflared_ids["site_a"]
        config    = { ingress = [{ service = "http_status:404" }] }
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].account_id == var.account_id && cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].tunnel_id == "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415"
    error_message = "The configuration must target tunnel_id, in account_id."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config.origin_request == null && cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config.ingress[0].origin_request == null
    error_message = "Left out, origin_request must stay unset, at both levels."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config.ingress[0].hostname == null && cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config.ingress[0].path == null
    error_message = "Left out, hostname and path must stay unset."
  }
}

run "complete_config" {
  variables {
    tunnel_cloudflared_configs = {
      site_a = {
        tunnel_id = run.tunnel.tunnel_cloudflared_ids["site_a"]
        source    = "cloudflare"
        config = {
          origin_request = {
            access                   = { aud_tag = ["8b4e2f6a1c3d5e7f9a0b2c4d6e8f0a1b3c5d7e9f1a2b4c6d8e0f2a4b6c8d0e2f"], team_name = "example", required = true }
            ca_pool                  = "/etc/cloudflared/ca.pem"
            connect_timeout          = 15
            disable_chunked_encoding = true
            http2_origin             = true
            http_host_header         = "app.internal"
            keep_alive_connections   = 50
            keep_alive_timeout       = 60
            match_sn_ito_host        = true
            no_happy_eyeballs        = true
            no_tls_verify            = false
            origin_server_name       = "app.internal"
            proxy_type               = "socks"
            tcp_keep_alive           = 20
            tls_timeout              = 5
          }
          ingress = [
            {
              hostname = "app.example.com"
              path     = "^/api/"
              service  = "https://localhost:8443"
              origin_request = {
                access                   = { aud_tag = ["1f3e5d7c9b0a2f4e6d8c0b1a3f5e7d9c2b4a6f8e0d1c3b5a7f9e2d4c6b8a0f1e"], team_name = "example" }
                ca_pool                  = "/etc/cloudflared/api-ca.pem"
                connect_timeout          = 10
                disable_chunked_encoding = false
                http2_origin             = false
                http_host_header         = "api.internal"
                keep_alive_connections   = 10
                keep_alive_timeout       = 30
                match_sn_ito_host        = false
                no_happy_eyeballs        = false
                no_tls_verify            = true
                origin_server_name       = "api.internal"
                proxy_type               = ""
                tcp_keep_alive           = 15
                tls_timeout              = 3
              }
            },
            { hostname = "app.example.com", service = "http://localhost:8080" },
            { service = "http_status:404" },
          ]
        }
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].source == "cloudflare"
    error_message = "source must reach the configuration."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config == var.tunnel_cloudflared_configs["site_a"].config
    error_message = "config must reach the configuration as given, every field of origin_request at both levels included."
  }

  assert {
    condition     = [for rule in cloudflare_zero_trust_tunnel_cloudflared_config.this["site_a"].config.ingress : rule.service] == ["https://localhost:8443", "http://localhost:8080", "http_status:404"]
    error_message = "The ingress rules must keep their order."
  }
}
