variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization and its Access objects. Changing it replaces every resource of the module."
  type        = string
}

variable "organization" {
  description = "Settings of the Zero Trust organization, with the attributes of `cloudflare_zero_trust_organization` under the same names. When `null`, the module leaves the organization alone. Terraform does not create the organization, and removing this argument resets nothing. The first apply resets the settings it leaves out: import the organization before, see [Organization](#organization)."
  type = object({
    allow_authenticate_via_warp = optional(bool)
    auth_domain                 = optional(string)
    auto_redirect_to_identity   = optional(bool)
    custom_pages = optional(object({
      forbidden       = optional(string)
      identity_denied = optional(string)
    }))
    deny_unmatched_requests                     = optional(bool)
    deny_unmatched_requests_exempted_zone_names = optional(list(string))
    is_ui_read_only                             = optional(bool)
    login_design = optional(object({
      background_color = optional(string)
      footer_text      = optional(string)
      header_text      = optional(string)
      logo_path        = optional(string)
      text_color       = optional(string)
    }))
    mfa_config = optional(object({
      allowed_authenticators        = optional(list(string))
      amr_matching_session_duration = optional(string)
      required_aaguids              = optional(string)
      session_duration              = optional(string)
    }))
    mfa_configuration_allowed = optional(bool)
    mfa_piv_key_requirements = optional(object({
      pin_policy          = optional(string)
      require_fips_device = optional(bool)
      ssh_key_size        = optional(list(number))
      ssh_key_type        = optional(list(string))
      touch_policy        = optional(string)
    }))
    mfa_required_for_all_apps = optional(bool)
    name                      = optional(string)
    service_token_inactivity = optional(object({
      action                    = string
      enabled                   = bool
      inactivity_threshold_days = number
    }))
    session_duration                   = optional(string)
    strict_service_token_auth          = optional(bool)
    ui_read_only_toggle_reason         = optional(string)
    user_seat_expiration_inactive_time = optional(string)
    warp_auth_non_browser_401          = optional(bool)
    warp_auth_session_duration         = optional(string)
  })
  default = null
}

variable "access_identity_providers" {
  description = "Identity providers, by a key of your choice. The key only names the provider in the state: keep it stable, since renaming a key replaces the provider. Each provider takes the attributes of `cloudflare_zero_trust_access_identity_provider` under the same names, with the fields of its `type` in `config`. Changing `type` replaces the provider. See [Identity providers](#identity-providers)."
  type = map(object({
    config = object({
      apps_domain                = optional(string)
      attributes                 = optional(list(string))
      auth_url                   = optional(string)
      authorization_server_id    = optional(string)
      centrify_account           = optional(string)
      centrify_app_id            = optional(string)
      certs_url                  = optional(string)
      claims                     = optional(list(string))
      client_id                  = optional(string)
      client_secret              = optional(string)
      conditional_access_enabled = optional(bool)
      directory_id               = optional(string)
      email_attribute_name       = optional(string)
      email_claim_name           = optional(string)
      enable_encryption          = optional(bool)
      force_authn                = optional(bool)
      header_attributes = optional(list(object({
        attribute_name = optional(string)
        header_name    = optional(string)
      })))
      idp_public_certs            = optional(list(string))
      issuer_url                  = optional(string)
      login_page_auto_prompt      = optional(bool)
      max_sso_url_length          = optional(number)
      okta_account                = optional(string)
      onelogin_account            = optional(string)
      ping_env_id                 = optional(string)
      pkce_enabled                = optional(bool)
      prompt                      = optional(string)
      restrict_to_account_members = optional(bool)
      scopes                      = optional(list(string))
      sign_request                = optional(bool)
      sso_target_url              = optional(string)
      support_groups              = optional(bool)
      token_url                   = optional(string)
      use_login_hint              = optional(bool)
    })
    name                    = string
    type                    = string
    read_only               = optional(bool)
    saml_certificate_set_id = optional(string)
    scim_config = optional(object({
      enabled                  = optional(bool)
      identity_update_behavior = optional(string)
      seat_deprovision         = optional(bool)
      user_deprovision         = optional(bool)
    }))
  }))
  default = {}
}

variable "access_groups" {
  description = "Access groups, by a key of your choice. The key only names the group in the state: keep it stable, since renaming a key replaces the group. Each group takes the attributes of `cloudflare_zero_trust_access_group` under the same names. Each rule of `include`, `exclude` and `require` sets one selector, such as `{ email_domain = { domain = \"example.com\" } }` or `{ everyone = {} }`. See [Groups and policies](#groups-and-policies)."
  type = map(object({
    include = list(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    }))
    name = string
    exclude = optional(list(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    is_default = optional(bool)
    require = optional(list(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
  }))
  default = {}
}

variable "access_policies" {
  description = "Reusable Access policies, by a key of your choice. The key only names the policy in the state: keep it stable, since renaming a key replaces the policy. Each policy takes the attributes of `cloudflare_zero_trust_access_policy` under the same names, with the rules of `access_groups`. Refer to a group of the module with `group = { id = module.<name>.access_group_ids[\"<key>\"] }`. See [Groups and policies](#groups-and-policies)."
  type = map(object({
    decision = string
    name     = string
    approval_groups = optional(set(object({
      approvals_needed = number
      email_addresses  = optional(list(string))
      email_list_uuid  = optional(string)
    })))
    approval_required = optional(bool)
    connection_rules = optional(object({
      rdp = optional(object({
        allowed_clipboard_local_to_remote_formats = optional(list(string))
        allowed_clipboard_remote_to_local_formats = optional(list(string))
      }))
    }))
    exclude = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    include = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    isolation_required = optional(bool)
    mfa_config = optional(object({
      allowed_authenticators = optional(list(string))
      mfa_disabled           = optional(bool)
      session_duration       = optional(string)
    }))
    purpose_justification_prompt   = optional(string)
    purpose_justification_required = optional(bool)
    require = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
        account_id      = optional(string)
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    session_duration = optional(string)
  }))
  default = {}
}
