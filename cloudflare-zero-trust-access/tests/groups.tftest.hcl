mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_group" {
    defaults = {
      id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_groups" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_group.this) == 0
    error_message = "Without access_groups, the module must not create any."
  }
}

run "group_minimal" {
  command = plan

  variables {
    access_groups = {
      staff = {
        name    = "Staff"
        include = [{ email_domain = { domain = "example.com" } }]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_group.this["staff"].account_id == var.account_id &&
      cloudflare_zero_trust_access_group.this["staff"].zone_id == null &&
      cloudflare_zero_trust_access_group.this["staff"].name == "Staff"
    )
    error_message = "The group must belong to account_id, with its name as given."
  }

  assert {
    condition     = cloudflare_zero_trust_access_group.this["staff"].include[0].email_domain.domain == "example.com"
    error_message = "include must reach the group."
  }

  assert {
    condition = alltrue([
      for kind, value in cloudflare_zero_trust_access_group.this["staff"].include[0] : value == null
      if kind != "email_domain"
    ])
    error_message = "A rule must set only its own selector."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_group.this["staff"].exclude == null &&
      cloudflare_zero_trust_access_group.this["staff"].require == null &&
      cloudflare_zero_trust_access_group.this["staff"].is_default == null
    )
    error_message = "exclude, require and is_default must stay unset."
  }
}

# One rule per selector, the 26 of the provider. The selectors without
# attributes must reach the provider as an empty object, not null.
run "every_selector" {
  command = plan

  variables {
    access_groups = {
      all = {
        name = "Every selector"
        include = [
          { any_valid_service_token = {} },
          { auth_context = { ac_id = "c1", id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f", identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { auth_method = { auth_method = "mfa" } },
          { azure_ad = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f", identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { certificate = {} },
          { cloudflare_account_member = {} },
          { common_name = { common_name = "client.example.com" } },
          { device_posture = { integration_uid = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { email = { email = "user@example.com" } },
          { email_domain = { domain = "example.com" } },
          { email_list = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { everyone = {} },
          { external_evaluation = { evaluate_url = "https://eval.example.com", keys_url = "https://eval.example.com/keys" } },
          { geo = { country_code = "FR" } },
          { github_organization = { identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971", name = "example", team = "admins" } },
          { group = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { gsuite = { email = "admins@example.com", identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { ip = { ip = "192.0.2.0/24" } },
          { ip_list = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { linked_app_token = { app_uid = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { login_method = { id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { oidc = { claim_name = "groups", claim_value = "admins", identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { okta = { identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971", name = "admins" } },
          { saml = { attribute_name = "group", attribute_value = "admins", identity_provider_id = "ea85612a-29c8-46c2-bacb-669d65136971" } },
          { service_token = { token_id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } },
          { user_risk_score = { user_risk_score = ["low", "medium"] } },
        ]
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_access_group.this["all"].include == var.access_groups["all"].include
    error_message = "Every rule of include must reach the group, in order."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_group.this["all"].include[0].any_valid_service_token != null &&
      cloudflare_zero_trust_access_group.this["all"].include[4].certificate != null &&
      cloudflare_zero_trust_access_group.this["all"].include[5].cloudflare_account_member != null &&
      cloudflare_zero_trust_access_group.this["all"].include[11].everyone != null
    )
    error_message = "A selector without attributes must reach the provider as an empty object."
  }
}

run "group" {
  variables {
    access_groups = {
      admins = {
        name       = "Admins"
        include    = [{ email = { email = "admin@example.com" } }, { group = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } }]
        exclude    = [{ geo = { country_code = "KP" } }]
        require    = [{ auth_method = { auth_method = "hwk" } }, { device_posture = { integration_uid = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f", account_id = "023e105f4ecef8ad9ca31a8372d0c353" } }]
        is_default = true
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_group.this["admins"].include == var.access_groups["admins"].include &&
      cloudflare_zero_trust_access_group.this["admins"].exclude == var.access_groups["admins"].exclude &&
      cloudflare_zero_trust_access_group.this["admins"].require == var.access_groups["admins"].require
    )
    error_message = "include, exclude and require must reach the group."
  }

  assert {
    condition     = cloudflare_zero_trust_access_group.this["admins"].is_default == true
    error_message = "is_default must reach the group."
  }

  assert {
    condition     = output.access_group_ids == { admins = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" }
    error_message = "access_group_ids must give the ID of each group, by key."
  }
}
