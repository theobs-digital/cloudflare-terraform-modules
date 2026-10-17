mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "managed_networks_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_managed_networks.this) == 0
    error_message = "Without device_managed_networks, the module must not manage any managed network."
  }
}

run "managed_networks" {
  variables {
    device_managed_networks = {
      office = {
        name = "Office"
        type = "tls"
        config = {
          tls_sockaddr = "192.0.2.20:443"
          sha256       = "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
        }
      }
      lab = {
        name   = "Lab"
        type   = "tls"
        config = { tls_sockaddr = "lab.example:8443" }
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_managed_networks.this["office"].account_id == var.account_id &&
      cloudflare_zero_trust_device_managed_networks.this["office"].name == "Office" &&
      cloudflare_zero_trust_device_managed_networks.this["office"].type == "tls" &&
      cloudflare_zero_trust_device_managed_networks.this["office"].config == var.device_managed_networks["office"].config
    )
    error_message = "Every attribute must reach the managed network."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_managed_networks.this["lab"].config.tls_sockaddr == "lab.example:8443" &&
      cloudflare_zero_trust_device_managed_networks.this["lab"].config.sha256 == ""
    )
    error_message = "Without sha256, the module must send an empty sha256, as Cloudflare returns it."
  }

  assert {
    condition = output.device_managed_network_ids == {
      office = cloudflare_zero_trust_device_managed_networks.this["office"].id
      lab    = cloudflare_zero_trust_device_managed_networks.this["lab"].id
    }
    error_message = "device_managed_network_ids must give the ID of each managed network, by key."
  }
}
