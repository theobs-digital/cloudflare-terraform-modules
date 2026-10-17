mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_infrastructure_target" {
    defaults = {
      id = "0e1f2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b"
      # Settings unlike the ones the tests give, which must win.
      tags = { computed = "true" }
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_infrastructure_targets" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_infrastructure_target.this) == 0
    error_message = "Without access_infrastructure_targets, the module must not create any."
  }
}

run "infrastructure_target_minimal" {
  command = plan

  variables {
    access_infrastructure_targets = {
      db1 = {
        hostname = "db-1"
        ip       = { ipv4 = { ip_addr = "10.0.0.11" } }
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_infrastructure_target.this["db1"].account_id == var.account_id &&
      cloudflare_zero_trust_access_infrastructure_target.this["db1"].hostname == "db-1" &&
      cloudflare_zero_trust_access_infrastructure_target.this["db1"].ip.ipv4.ip_addr == "10.0.0.11" &&
      cloudflare_zero_trust_access_infrastructure_target.this["db1"].ip.ipv6 == null
    )
    error_message = "The target must belong to account_id, with hostname and ip as given."
  }
}

run "infrastructure_target" {
  variables {
    access_infrastructure_targets = {
      db1 = {
        hostname = "db-1"
        ip = {
          ipv4 = { ip_addr = "10.0.0.11", virtual_network_id = "c77b744e-acc8-428f-9257-6878c046ed55" }
          ipv6 = { ip_addr = "fd00::11", virtual_network_id = "c77b744e-acc8-428f-9257-6878c046ed55" }
        }
        tags = { environment = "production", team = "platform" }
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_access_infrastructure_target.this["db1"].ip == var.access_infrastructure_targets["db1"].ip
    error_message = "Both addresses must reach the target, with their virtual network."
  }

  assert {
    condition     = cloudflare_zero_trust_access_infrastructure_target.this["db1"].tags == tomap({ environment = "production", team = "platform" })
    error_message = "tags must reach the target."
  }

  assert {
    condition     = output.access_infrastructure_target_ids == { db1 = "0e1f2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b" }
    error_message = "access_infrastructure_target_ids must give the ID of each target."
  }
}
