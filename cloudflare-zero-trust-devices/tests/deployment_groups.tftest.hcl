mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "deployment_groups_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_deployment_groups.this) == 0
    error_message = "Without device_deployment_groups, the module must not manage any deployment group."
  }

  assert {
    condition     = output.device_default_profile_policy_id == null
    error_message = "Without device_default_profile, device_default_profile_policy_id must be null."
  }
}

run "profiles" {
  variables {
    device_default_profile = { tunnel_protocol = "masque" }
    device_custom_profiles = {
      ring0 = { name = "Ring 0", match = "identity.groups.name == \"IT\"", precedence = 100 }
      ring1 = { name = "Ring 1", match = "identity.groups.name == \"Engineering\"", precedence = 200 }
    }
  }
}

# policy_ids comes from the device_custom_profile_ids and
# device_default_profile_policy_id outputs, as a caller writes it. The
# profiles are those of the previous run, unchanged, so they keep their IDs.
run "deployment_groups" {
  variables {
    device_default_profile = { tunnel_protocol = "masque" }
    device_custom_profiles = {
      ring0 = { name = "Ring 0", match = "identity.groups.name == \"IT\"", precedence = 100 }
      ring1 = { name = "Ring 1", match = "identity.groups.name == \"Engineering\"", precedence = 200 }
    }
    device_deployment_groups = {
      ring0 = {
        name = "Ring 0"
        version_config = [
          { target_environment = "windows", version = "2026.8.2110.0" },
          { target_environment = "macos", version = "2026.8.2110.0" },
        ]
        policy_ids = [run.profiles.device_custom_profile_ids["ring0"]]
      }
      everyone = {
        name           = "Everyone"
        version_config = [{ target_environment = "windows", version = "2026.8.2100.0" }]
      }
      default = {
        name           = "Default profile"
        version_config = [{ target_environment = "macos", version = "2026.8.2100.0" }]
        policy_ids     = [run.profiles.device_default_profile_policy_id]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_deployment_groups.this["ring0"].account_id == var.account_id &&
      cloudflare_zero_trust_device_deployment_groups.this["ring0"].name == "Ring 0" &&
      cloudflare_zero_trust_device_deployment_groups.this["ring0"].version_config == var.device_deployment_groups["ring0"].version_config
    )
    error_message = "Every attribute must reach the deployment group."
  }

  assert {
    condition     = cloudflare_zero_trust_device_deployment_groups.this["ring0"].policy_ids == tolist([cloudflare_zero_trust_device_custom_profile.this["ring0"].id])
    error_message = "A deployment group must reach the profiles that policy_ids names."
  }

  assert {
    condition = (
      output.device_default_profile_policy_id == cloudflare_zero_trust_device_default_profile.this[0].policy_id &&
      cloudflare_zero_trust_device_deployment_groups.this["default"].policy_ids == tolist([cloudflare_zero_trust_device_default_profile.this[0].policy_id])
    )
    error_message = "device_default_profile_policy_id must give the policy_id of the default profile, which a deployment group reaches."
  }

  assert {
    condition     = cloudflare_zero_trust_device_deployment_groups.this["everyone"].policy_ids == null
    error_message = "Without policy_ids, the module must send none."
  }

  assert {
    condition = output.device_deployment_group_ids == {
      ring0    = cloudflare_zero_trust_device_deployment_groups.this["ring0"].id
      everyone = cloudflare_zero_trust_device_deployment_groups.this["everyone"].id
      default  = cloudflare_zero_trust_device_deployment_groups.this["default"].id
    }
    error_message = "device_deployment_group_ids must give the ID of each deployment group, by key."
  }
}
