mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_policy" {
    defaults = {
      id = "f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f"
      # Rules unlike the ones the tests give, which must win.
      exclude = [{ ip = { ip = "203.0.113.0/24" } }]
      require = [{ ip = { ip = "203.0.113.0/24" } }]
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_policies" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_policy.this) == 0
    error_message = "Without access_policies, the module must not create any."
  }
}

# exclude, include and require are computed: the mock fills them when left
# out, the provider keeps them null.
run "policy_minimal" {
  command = plan

  variables {
    access_policies = {
      staff = {
        name     = "Staff"
        decision = "allow"
        include  = [{ email_domain = { domain = "example.com" } }]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["staff"].account_id == var.account_id &&
      cloudflare_zero_trust_access_policy.this["staff"].name == "Staff" &&
      cloudflare_zero_trust_access_policy.this["staff"].decision == "allow"
    )
    error_message = "The policy must belong to account_id, with name and decision as given."
  }

  assert {
    condition     = cloudflare_zero_trust_access_policy.this["staff"].include == var.access_policies["staff"].include
    error_message = "include must reach the policy."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["staff"].approval_groups == null &&
      cloudflare_zero_trust_access_policy.this["staff"].approval_required == null &&
      cloudflare_zero_trust_access_policy.this["staff"].connection_rules == null &&
      cloudflare_zero_trust_access_policy.this["staff"].isolation_required == null &&
      cloudflare_zero_trust_access_policy.this["staff"].mfa_config == null &&
      cloudflare_zero_trust_access_policy.this["staff"].purpose_justification_prompt == null &&
      cloudflare_zero_trust_access_policy.this["staff"].purpose_justification_required == null &&
      cloudflare_zero_trust_access_policy.this["staff"].session_duration == null
    )
    error_message = "Attributes left out must stay unset."
  }
}

# One rule per selector, the 26 of the provider.
run "every_selector" {
  command = plan

  variables {
    access_policies = {
      all = {
        name     = "Every selector"
        decision = "allow"
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
    condition     = cloudflare_zero_trust_access_policy.this["all"].include == var.access_policies["all"].include
    error_message = "Every rule of include must reach the policy."
  }

  assert {
    condition = (
      length([for rule in cloudflare_zero_trust_access_policy.this["all"].include : rule if rule.any_valid_service_token != null]) == 1 &&
      length([for rule in cloudflare_zero_trust_access_policy.this["all"].include : rule if rule.certificate != null]) == 1 &&
      length([for rule in cloudflare_zero_trust_access_policy.this["all"].include : rule if rule.cloudflare_account_member != null]) == 1 &&
      length([for rule in cloudflare_zero_trust_access_policy.this["all"].include : rule if rule.everyone != null]) == 1
    )
    error_message = "A selector without attributes must reach the provider as an empty object."
  }
}

run "policy" {
  variables {
    access_policies = {
      admins = {
        name     = "Admins"
        decision = "allow"
        include  = [{ group = { id = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" } }]
        exclude  = [{ geo = { country_code = "KP" } }]
        require  = [{ auth_method = { auth_method = "hwk" } }]
        approval_groups = [
          { approvals_needed = 1, email_addresses = ["approver@example.com"] },
          { approvals_needed = 2, email_list_uuid = "aa0a4aab-672b-4bdb-bc33-a59f1130a11f" },
        ]
        approval_required = true
        connection_rules = {
          rdp = {
            allowed_clipboard_local_to_remote_formats = ["text"]
            allowed_clipboard_remote_to_local_formats = ["text"]
          }
        }
        isolation_required = true
        mfa_config = {
          allowed_authenticators = ["totp", "security_key"]
          mfa_disabled           = false
          session_duration       = "12h"
        }
        purpose_justification_prompt   = "Why do you need access?"
        purpose_justification_required = true
        session_duration               = "8h"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["admins"].include == var.access_policies["admins"].include &&
      cloudflare_zero_trust_access_policy.this["admins"].exclude == var.access_policies["admins"].exclude &&
      cloudflare_zero_trust_access_policy.this["admins"].require == var.access_policies["admins"].require
    )
    error_message = "include, exclude and require must reach the policy."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["admins"].approval_groups == var.access_policies["admins"].approval_groups &&
      cloudflare_zero_trust_access_policy.this["admins"].approval_required == true
    )
    error_message = "approval_groups and approval_required must reach the policy."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["admins"].connection_rules == var.access_policies["admins"].connection_rules &&
      cloudflare_zero_trust_access_policy.this["admins"].mfa_config == var.access_policies["admins"].mfa_config
    )
    error_message = "Every field of connection_rules and mfa_config must reach the policy."
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_policy.this["admins"].isolation_required == true &&
      cloudflare_zero_trust_access_policy.this["admins"].purpose_justification_prompt == "Why do you need access?" &&
      cloudflare_zero_trust_access_policy.this["admins"].purpose_justification_required == true &&
      cloudflare_zero_trust_access_policy.this["admins"].session_duration == "8h"
    )
    error_message = "isolation_required, purpose_justification_prompt, purpose_justification_required and session_duration must reach the policy."
  }

  assert {
    condition     = output.access_policy_ids == { admins = "f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f" }
    error_message = "access_policy_ids must give the ID of each policy, by key."
  }
}
