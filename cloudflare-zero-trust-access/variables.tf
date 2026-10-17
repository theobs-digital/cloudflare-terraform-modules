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

variable "access_applications" {
  description = "Access applications, by a key of your choice. The key only names the application in the state: keep it stable, since renaming a key replaces the application. Each application takes the attributes of `cloudflare_zero_trust_access_application` under the same names. Set `type`: without it, the provider refuses the attributes specific to a type. `policies` refers to reusable policies by ID, such as `{ id = module.<name>.access_policy_ids[\"<key>\"], precedence = 1 }`, except for an `infrastructure` application, which takes policies written inside it, with `connection_rules`. See [Applications](#applications)."
  type = map(object({
    allow_authenticate_via_warp = optional(bool)
    allow_iframe                = optional(bool)
    allowed_idps                = optional(set(string))
    app_launcher_logo_url       = optional(string)
    app_launcher_visible        = optional(bool)
    auto_redirect_to_identity   = optional(bool)
    bg_color                    = optional(string)
    cors_headers = optional(object({
      allow_all_headers = optional(bool)
      allow_all_methods = optional(bool)
      allow_all_origins = optional(bool)
      allow_credentials = optional(bool)
      allowed_headers   = optional(set(string))
      allowed_methods   = optional(set(string))
      allowed_origins   = optional(set(string))
      max_age           = optional(number)
    }))
    custom_deny_message          = optional(string)
    custom_deny_url              = optional(string)
    custom_non_identity_deny_url = optional(string)
    custom_pages                 = optional(list(string))
    destinations = optional(list(object({
      cidr          = optional(string)
      hostname      = optional(string)
      l4_protocol   = optional(string)
      mcp_server_id = optional(string)
      port_range    = optional(string)
      type          = optional(string)
      uri           = optional(string)
      vnet_id       = optional(string)
      worker_id     = optional(string)
    })))
    domain                = optional(string)
    enable_binding_cookie = optional(bool)
    footer_links = optional(list(object({
      name = string
      url  = string
    })))
    header_bg_color            = optional(string)
    http_only_cookie_attribute = optional(bool)
    landing_page_design = optional(object({
      button_color      = optional(string)
      button_text_color = optional(string)
      image_url         = optional(string)
      message           = optional(string)
      title             = optional(string)
    }))
    logo_url = optional(string)
    mfa_config = optional(object({
      allowed_authenticators = optional(list(string))
      mfa_disabled           = optional(bool)
      session_duration       = optional(string)
    }))
    name = optional(string)
    oauth_configuration = optional(object({
      dynamic_client_registration = optional(object({
        allow_any_on_localhost = optional(bool)
        allow_any_on_loopback  = optional(bool)
        allowed_uris           = optional(list(string))
        enabled                = optional(bool)
      }))
      enabled = optional(bool)
      grant = optional(object({
        access_token_lifetime = optional(string)
        session_duration      = optional(string)
      }))
    }))
    options_preflight_bypass = optional(bool)
    path_cookie_attribute    = optional(bool)
    policies = optional(list(object({
      connection_rules = optional(object({
        rdp = optional(object({
          allowed_clipboard_local_to_remote_formats = optional(list(string))
          allowed_clipboard_remote_to_local_formats = optional(list(string))
        }))
        ssh = optional(object({
          usernames         = list(string)
          allow_email_alias = optional(bool)
        }))
      }))
      decision = optional(string)
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
        common_name = optional(object({
          common_name = string
        }))
        device_posture = optional(object({
          integration_uid = string
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
      })))
      id = optional(string)
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
        common_name = optional(object({
          common_name = string
        }))
        device_posture = optional(object({
          integration_uid = string
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
      })))
      mfa_config = optional(object({
        allowed_authenticators = optional(list(string))
        mfa_disabled           = optional(bool)
        session_duration       = optional(string)
      }))
      name       = optional(string)
      precedence = optional(number)
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
        common_name = optional(object({
          common_name = string
        }))
        device_posture = optional(object({
          integration_uid = string
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
      })))
    })))
    read_service_tokens_from_header = optional(string)
    saas_app = optional(object({
      access_token_lifetime            = optional(string)
      allow_pkce_without_client_secret = optional(bool)
      app_launcher_url                 = optional(string)
      auth_type                        = optional(string)
      consumer_service_url             = optional(string)
      custom_attributes = optional(list(object({
        friendly_name = optional(string)
        name          = optional(string)
        name_format   = optional(string)
        required      = optional(bool)
        source = optional(object({
          name = optional(string)
          name_by_idp = optional(list(object({
            idp_id      = optional(string)
            source_name = optional(string)
          })))
        }))
      })))
      custom_claims = optional(list(object({
        name     = optional(string)
        required = optional(bool)
        scope    = optional(string)
        source = optional(object({
          name        = optional(string)
          name_by_idp = optional(map(string))
        }))
      })))
      default_relay_state = optional(string)
      grant_types         = optional(list(string))
      group_filter_regex  = optional(string)
      hybrid_and_implicit_options = optional(object({
        return_access_token_from_authorization_endpoint = optional(bool)
        return_id_token_from_authorization_endpoint     = optional(bool)
      }))
      idp_entity_id             = optional(string)
      name_id_format            = optional(string)
      name_id_transform_jsonata = optional(string)
      redirect_uris             = optional(list(string))
      refresh_token_options = optional(object({
        lifetime = optional(string)
      }))
      saml_attribute_transform_jsonata = optional(string)
      scopes                           = optional(list(string))
      sp_entity_id                     = optional(string)
      sso_endpoint                     = optional(string)
    }))
    same_site_cookie_attribute = optional(string)
    scim_config = optional(object({
      idp_uid    = string
      remote_uri = string
      authentication = optional(object({
        scheme            = string
        authorization_url = optional(string)
        client_id         = optional(string)
        client_secret     = optional(string)
        password          = optional(string)
        scopes            = optional(list(string))
        token             = optional(string)
        token_url         = optional(string)
        user              = optional(string)
      }))
      deactivate_on_delete = optional(bool)
      enabled              = optional(bool)
      mappings = optional(list(object({
        schema  = string
        enabled = optional(bool)
        filter  = optional(string)
        operations = optional(object({
          create = optional(bool)
          delete = optional(bool)
          update = optional(bool)
        }))
        strictness        = optional(string)
        transform_jsonata = optional(string)
      })))
    }))
    service_auth_401_redirect    = optional(bool)
    session_duration             = optional(string)
    skip_app_launcher_login_page = optional(bool)
    skip_interstitial            = optional(bool)
    tags                         = optional(set(string))
    target_criteria = optional(list(object({
      port     = number
      protocol = string
      exclude = optional(object({
        tags = optional(map(list(string)))
        target_attributes = optional(object({
          hostname = list(string)
        }))
      }))
      include = optional(object({
        tags = optional(map(list(string)))
        target_attributes = optional(object({
          hostname = list(string)
        }))
      }))
      require = optional(object({
        tags = optional(map(list(string)))
        target_attributes = optional(object({
          hostname = list(string)
        }))
      }))
      target_attributes = optional(map(list(string)))
    })))
    type = optional(string)
  }))
  default = {}
}

variable "access_service_tokens" {
  description = "Service tokens, by a key of your choice. The key only names the token in the state: keep it stable, since renaming a key replaces the token and its credentials. Each token takes the attributes of `cloudflare_zero_trust_access_service_token` under the same names. To rotate the secret, increment `client_secret_version` and set `previous_client_secret_expires_at`, together. See [Service tokens](#service-tokens)."
  type = map(object({
    name                              = string
    client_secret_version             = optional(number)
    duration                          = optional(string)
    enabled                           = optional(bool)
    previous_client_secret_expires_at = optional(string)
  }))
  default = {}
}

variable "access_mtls_certificates" {
  description = "mTLS certificates: the certificate authorities that sign the client certificates Access accepts, by a key of your choice. The key only names the certificate in the state: keep it stable, since renaming a key replaces the certificate. Each certificate takes the attributes of `cloudflare_zero_trust_access_mtls_certificate` under the same names, with the PEM of the CA in `certificate`. Changing `certificate` replaces it. See [mTLS](#mtls)."
  type = map(object({
    certificate          = string
    name                 = string
    associated_hostnames = optional(set(string))
  }))
  default = {}
}

variable "access_mtls_hostname_settings" {
  description = "mTLS settings of the account's hostnames, with the attributes of `cloudflare_zero_trust_access_mtls_hostname_settings` under the same names. When `null`, the module leaves them alone. `settings` replaces the whole list of the account, and removing this argument resets nothing. See [mTLS](#mtls)."
  type = object({
    settings = list(object({
      china_network                 = bool
      client_certificate_forwarding = bool
      hostname                      = string
    }))
  })
  default = null
}

variable "access_short_lived_certificates" {
  description = "Short-lived certificate CAs, one per SSH application, by a key of your choice. The key only names the CA in the state: keep it stable, since renaming a key replaces the CA, and its public key. Each takes the `app_id` of `cloudflare_zero_trust_access_short_lived_certificate`, such as `module.<name>.access_application_ids[\"<key>\"]`. Changing `app_id` replaces the CA, and its public key. See [Short-lived certificates](#short-lived-certificates)."
  type = map(object({
    app_id = string
  }))
  default = {}
}

variable "access_tags" {
  description = "Tags of Access applications, by a key of your choice. The key only names the tag in the state: keep it stable, since renaming a key replaces the tag. Each tag takes the `name` of `cloudflare_zero_trust_access_tag`, which is also its ID: changing it replaces the tag. An application of the same call refers to a tag with `tags = [module.<name>.access_tag_ids[\"<key>\"]]`. See [Tags and custom pages](#tags-and-custom-pages)."
  type = map(object({
    name = string
  }))
  default = {}
}

variable "access_custom_pages" {
  description = "Custom pages of Access, by a key of your choice. The key only names the page in the state: keep it stable, since renaming a key replaces the page. Each page takes the attributes of `cloudflare_zero_trust_access_custom_page` under the same names. An application refers to a page with `custom_pages = [module.<name>.access_custom_page_ids[\"<key>\"]]`. See [Tags and custom pages](#tags-and-custom-pages)."
  type = map(object({
    custom_html      = string
    name             = string
    type             = string
    contract_version = optional(number)
  }))
  default = {}
}

variable "access_key_configuration" {
  description = "Rotation of the keys that sign Access tokens, with the attribute of `cloudflare_zero_trust_access_key_configuration`. When `null`, the module leaves it alone, and removing this argument resets nothing. See [Signing keys](#signing-keys)."
  type = object({
    key_rotation_interval_days = number
  })
  default = null
}

variable "access_infrastructure_targets" {
  description = "Infrastructure targets: the servers that `infrastructure` applications protect, by a key of your choice. The key only names the target in the state: keep it stable, since renaming a key replaces the target. Each target takes the attributes of `cloudflare_zero_trust_access_infrastructure_target` under the same names. See [Infrastructure targets](#infrastructure-targets)."
  type = map(object({
    hostname = string
    ip = object({
      ipv4 = optional(object({
        ip_addr            = optional(string)
        virtual_network_id = optional(string)
      }))
      ipv6 = optional(object({
        ip_addr            = optional(string)
        virtual_network_id = optional(string)
      }))
    })
    tags = optional(map(string))
  }))
  default = {}
}

variable "access_ai_controls_mcp_servers" {
  description = "MCP servers of AI controls, by a key of your choice. The key only names the server in the state: keep it stable, since renaming a key replaces the server. Each server takes the attributes of `cloudflare_zero_trust_access_ai_controls_mcp_server` under the same names, with an `id` of your choice. Changing `id`, `auth_type` or `hostname` replaces the server. Keep `auth_credentials` and `client_secret` out of versioned files. See [MCP servers and portals](#mcp-servers-and-portals)."
  type = map(object({
    auth_type                        = string
    hostname                         = string
    id                               = string
    name                             = string
    auth_credentials                 = optional(string)
    client_secret                    = optional(string)
    description                      = optional(string)
    is_shared_oauth_callback_enabled = optional(bool)
    secure_web_gateway               = optional(bool)
    updated_prompts = optional(list(object({
      name        = string
      alias       = optional(string)
      description = optional(string)
      enabled     = optional(bool)
    })))
    updated_tools = optional(list(object({
      name        = string
      alias       = optional(string)
      description = optional(string)
      enabled     = optional(bool)
    })))
  }))
  default = {}
}

variable "access_ai_controls_mcp_portals" {
  description = "MCP portals of AI controls, by a key of your choice. The key only names the portal in the state: keep it stable, since renaming a key replaces the portal. Each portal takes the attributes of `cloudflare_zero_trust_access_ai_controls_mcp_portal` under the same names, but the deprecated `allow_code_mode`, with an `id` of your choice: changing `id` replaces the portal. A portal refers to a server of the same call with `server_id = module.<name>.access_ai_controls_mcp_server_ids[\"<key>\"]`. See [MCP servers and portals](#mcp-servers-and-portals)."
  type = map(object({
    hostname           = string
    id                 = string
    name               = string
    code_mode          = optional(string)
    description        = optional(string)
    secure_web_gateway = optional(bool)
    servers = optional(set(object({
      server_id        = string
      default_disabled = optional(bool)
      on_behalf        = optional(bool)
      updated_prompts = optional(list(object({
        name        = string
        alias       = optional(string)
        description = optional(string)
        enabled     = optional(bool)
      })))
      updated_tools = optional(list(object({
        name        = string
        alias       = optional(string)
        description = optional(string)
        enabled     = optional(bool)
      })))
    })))
  }))
  default = {}
}
