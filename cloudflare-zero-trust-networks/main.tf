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

resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" "this" {
  for_each = var.tunnel_cloudflared_virtual_networks

  account_id         = var.account_id
  name               = each.value.name
  comment            = each.value.comment
  is_default_network = each.value.is_default_network
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "this" {
  for_each = var.tunnel_cloudflared_routes

  account_id         = var.account_id
  network            = each.value.network
  tunnel_id          = each.value.tunnel_id
  comment            = each.value.comment
  virtual_network_id = each.value.virtual_network_id
}

resource "cloudflare_zero_trust_network_hostname_route" "this" {
  for_each = var.network_hostname_routes

  account_id = var.account_id
  hostname   = each.value.hostname
  tunnel_id  = each.value.tunnel_id
  comment    = each.value.comment
}
