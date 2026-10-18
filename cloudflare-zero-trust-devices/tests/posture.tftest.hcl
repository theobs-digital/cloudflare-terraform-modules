mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "posture_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_posture_integration.this) == 0
    error_message = "Without device_posture_integrations, the module must not manage any posture integration."
  }

  assert {
    condition     = length(cloudflare_zero_trust_device_posture_rule.this) == 0
    error_message = "Without device_posture_rules, the module must not manage any posture rule."
  }
}

# Every field of input in one rule: the mock does not check them against the
# type. Booleans are true, as a bool left out would come out false.
run "posture_rules" {
  variables {
    device_posture_rules = {
      every_input = {
        name        = "Every input"
        type        = "client_certificate_v2"
        description = "Every field of input"
        expiration  = "1h"
        schedule    = "10m"
        match       = [{ platform = "mac" }, { platform = "windows" }]
        input = {
          active_threats     = 1
          auth_state         = ["Good", "Will Block"]
          certificate_id     = "b14ddcc4-bcbf-4c73-9c39-e1a1e7f5e9ef"
          check_disks        = ["C"]
          check_private_key  = true
          cn                 = "$${serial_number}"
          compliance_status  = "compliant"
          connection_id      = "bc7cbfbb-600a-42e4-8a23-45b5e85f804f"
          count_operator     = ">"
          domain             = "corp.example"
          eid_last_seen      = "1d"
          enabled            = true
          exists             = true
          extended_key_usage = ["clientAuth", "emailProtection"]
          id                 = "5a4a1fb8-0c0f-4dca-b4c7-3e3e1b9a4a1b"
          infected           = true
          is_active          = true
          issue_count        = "1"
          last_seen          = "1d"
          locations = {
            paths        = ["/etc/ssl/client.pem"]
            trust_stores = ["system"]
          }
          network_status            = "connected"
          operating_system          = "mac"
          operational_state         = "na"
          operator                  = ">="
          os                        = "os.name == \"macOS\""
          os_distro_name            = "ubuntu"
          os_distro_revision        = "24.04"
          os_version_extra          = "(a)"
          overall                   = "90"
          path                      = "/Applications/Example.app"
          require_all               = true
          risk_level                = "low"
          score                     = 50
          score_operator            = ">="
          sensor_config             = "90"
          sha256                    = "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
          state                     = "online"
          subject_alternative_names = ["laptop.corp.example"]
          thumbprint                = "0d6d5d7b6b2bc2a0e8d8f3d0e5f1c3b2a4f6e8d0"
          total_score               = 80
          update_window_days        = 7
          version                   = "15.0.0"
          version_operator          = ">="
        }
      }
      warp = {
        name = "WARP"
        type = "warp"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_posture_rule.this["every_input"].account_id == var.account_id &&
      cloudflare_zero_trust_device_posture_rule.this["every_input"].name == "Every input" &&
      cloudflare_zero_trust_device_posture_rule.this["every_input"].type == "client_certificate_v2" &&
      cloudflare_zero_trust_device_posture_rule.this["every_input"].description == "Every field of input" &&
      cloudflare_zero_trust_device_posture_rule.this["every_input"].expiration == "1h" &&
      cloudflare_zero_trust_device_posture_rule.this["every_input"].schedule == "10m"
    )
    error_message = "Every simple attribute must reach the posture rule."
  }

  assert {
    condition     = cloudflare_zero_trust_device_posture_rule.this["every_input"].input == var.device_posture_rules["every_input"].input
    error_message = "Every field of input must reach the posture rule."
  }

  assert {
    condition     = cloudflare_zero_trust_device_posture_rule.this["every_input"].match == var.device_posture_rules["every_input"].match
    error_message = "match must reach the posture rule, in order."
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_posture_rule.this["warp"].input == null &&
      cloudflare_zero_trust_device_posture_rule.this["warp"].match == null &&
      cloudflare_zero_trust_device_posture_rule.this["warp"].schedule == null
    )
    error_message = "A rule without input, match or schedule must send none."
  }

  assert {
    condition = output.device_posture_rule_ids == {
      every_input = cloudflare_zero_trust_device_posture_rule.this["every_input"].id
      warp        = cloudflare_zero_trust_device_posture_rule.this["warp"].id
    }
    error_message = "device_posture_rule_ids must give the ID of each posture rule, by key."
  }
}

# Integrations by mock only: at creation, Cloudflare checks the credentials
# with the third-party service.
run "posture_integrations" {
  variables {
    device_posture_integrations = {
      crowdstrike = {
        name     = "CrowdStrike"
        type     = "crowdstrike_s2s"
        interval = "10m"
        config = {
          api_url       = "https://api.crowdstrike.com"
          client_id     = "crowdstrike-client"
          client_secret = "crowdstrike-secret"
          customer_id   = "crowdstrike-customer"
        }
      }
      custom = {
        name     = "Custom"
        type     = "custom_s2s"
        interval = "1h"
        config = {
          api_url              = "https://posture.example/scores"
          access_client_id     = "88bf3b6d86161464f6509f7219099e57.access"
          access_client_secret = "access-secret"
        }
      }
      workspace_one = {
        name     = "Workspace ONE"
        type     = "workspace_one"
        interval = "12h"
        config = {
          api_url       = "https://as123.awmdm.com/api"
          auth_url      = "https://na.uemauth.vmwservices.com/connect/token"
          client_id     = "workspace-one-client"
          client_secret = "workspace-one-secret"
        }
      }
      uptycs = {
        name     = "Uptycs"
        type     = "uptycs"
        interval = "5m"
        config = {
          api_url     = "https://example.uptycs.io"
          client_id   = "uptycs-client"
          client_key  = "uptycs-key"
          customer_id = "uptycs-customer"
        }
      }
    }
  }

  assert {
    condition = alltrue([
      for key, integration in var.device_posture_integrations : (
        cloudflare_zero_trust_device_posture_integration.this[key].account_id == var.account_id &&
        cloudflare_zero_trust_device_posture_integration.this[key].name == integration.name &&
        cloudflare_zero_trust_device_posture_integration.this[key].type == integration.type &&
        cloudflare_zero_trust_device_posture_integration.this[key].interval == integration.interval
      )
    ])
    error_message = "account_id, name, type and interval must reach each posture integration."
  }

  assert {
    condition = alltrue([
      for key, integration in var.device_posture_integrations :
      cloudflare_zero_trust_device_posture_integration.this[key].config == integration.config
    ])
    error_message = "Every field of config, secrets included, must reach each posture integration."
  }

  assert {
    condition = output.device_posture_integration_ids == {
      for key, integration in cloudflare_zero_trust_device_posture_integration.this : key => integration.id
    }
    error_message = "device_posture_integration_ids must give the ID of each posture integration, by key."
  }
}

# connection_id comes from the device_posture_integration_ids output, as a
# caller writes it. The integration is the one of the previous run, unchanged,
# so it keeps its ID.
run "posture_rule_of_an_integration" {
  variables {
    device_posture_integrations = {
      crowdstrike = {
        name     = "CrowdStrike"
        type     = "crowdstrike_s2s"
        interval = "10m"
        config = {
          api_url       = "https://api.crowdstrike.com"
          client_id     = "crowdstrike-client"
          client_secret = "crowdstrike-secret"
          customer_id   = "crowdstrike-customer"
        }
      }
    }
    device_posture_rules = {
      crowdstrike = {
        name  = "CrowdStrike score"
        type  = "crowdstrike_s2s"
        match = [{ platform = "windows" }]
        input = {
          connection_id  = run.posture_integrations.device_posture_integration_ids["crowdstrike"]
          overall        = "70"
          score_operator = ">="
        }
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_device_posture_rule.this["crowdstrike"].input.connection_id == cloudflare_zero_trust_device_posture_integration.this["crowdstrike"].id
    error_message = "A rule must reach the integration that input.connection_id names."
  }
}
