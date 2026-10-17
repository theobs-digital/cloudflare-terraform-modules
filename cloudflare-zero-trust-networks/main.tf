resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  for_each = var.tunnel_cloudflareds

  account_id    = var.account_id
  name          = each.value.name
  config_src    = each.value.config_src
  tunnel_secret = each.value.tunnel_secret
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  for_each = var.tunnel_cloudflareds

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  for_each = var.tunnel_cloudflared_configs

  account_id = var.account_id
  tunnel_id  = each.value.tunnel_id
  config     = each.value.config
  source     = each.value.source
}
