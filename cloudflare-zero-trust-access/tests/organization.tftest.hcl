mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "organization_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_organization.this) == 0
    error_message = "Without organization, the module must not manage the organization."
  }
}

# The provider's defaults do not apply under the mock: only check that the
# module leaves out what the caller does.
run "organization_minimal" {
  command = plan

  variables {
    organization = {
      name        = "example"
      auth_domain = "example.cloudflareaccess.com"
    }
  }

  assert {
    condition     = cloudflare_zero_trust_organization.this[0].account_id == var.account_id
    error_message = "The organization must be the one of account_id."
  }

  assert {
    condition = (
      cloudflare_zero_trust_organization.this[0].name == "example" &&
      cloudflare_zero_trust_organization.this[0].auth_domain == "example.cloudflareaccess.com"
    )
    error_message = "name and auth_domain must reach the organization."
  }

  assert {
    condition = (
      cloudflare_zero_trust_organization.this[0].session_duration == null &&
      cloudflare_zero_trust_organization.this[0].deny_unmatched_requests == null &&
      cloudflare_zero_trust_organization.this[0].custom_pages == null &&
      cloudflare_zero_trust_organization.this[0].login_design == null &&
      cloudflare_zero_trust_organization.this[0].mfa_config == null &&
      cloudflare_zero_trust_organization.this[0].service_token_inactivity == null
    )
    error_message = "Attributes left out must stay unset."
  }
}

run "organization" {
  command = plan

  variables {
    organization = {
      allow_authenticate_via_warp = true
      auth_domain                 = "example.cloudflareaccess.com"
      auto_redirect_to_identity   = true
      custom_pages = {
        forbidden       = "699d98642c564d2e855e9661899b7252"
        identity_denied = "8f2e5b1a3c4d4e6f9a0b1c2d3e4f5a6b"
      }
      deny_unmatched_requests                     = true
      deny_unmatched_requests_exempted_zone_names = ["example.net"]
      is_ui_read_only                             = true
      login_design = {
        background_color = "#c5ed1b"
        footer_text      = "This is an example description."
        header_text      = "This is an example description."
        logo_path        = "https://example.com/logo.png"
        text_color       = "#c5ed1b"
      }
      mfa_config = {
        allowed_authenticators        = ["totp", "security_key"]
        amr_matching_session_duration = "12h"
        required_aaguids              = "cb69481e-8ff7-4039-93ec-0a2729a154a8"
        session_duration              = "24h"
      }
      mfa_configuration_allowed = true
      mfa_piv_key_requirements = {
        pin_policy          = "once"
        require_fips_device = true
        ssh_key_size        = [256, 384]
        ssh_key_type        = ["ecdsa", "ed25519"]
        touch_policy        = "always"
      }
      mfa_required_for_all_apps = true
      name                      = "example"
      service_token_inactivity = {
        action                    = "disable"
        enabled                   = true
        inactivity_threshold_days = 90
      }
      session_duration                   = "24h"
      strict_service_token_auth          = true
      ui_read_only_toggle_reason         = "Managed by Terraform"
      user_seat_expiration_inactive_time = "730h"
      warp_auth_non_browser_401          = true
      warp_auth_session_duration         = "24h"
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_organization.this[0].allow_authenticate_via_warp == true &&
      cloudflare_zero_trust_organization.this[0].auto_redirect_to_identity == true &&
      cloudflare_zero_trust_organization.this[0].deny_unmatched_requests == true &&
      cloudflare_zero_trust_organization.this[0].is_ui_read_only == true &&
      cloudflare_zero_trust_organization.this[0].mfa_configuration_allowed == true &&
      cloudflare_zero_trust_organization.this[0].mfa_required_for_all_apps == true &&
      cloudflare_zero_trust_organization.this[0].strict_service_token_auth == true &&
      cloudflare_zero_trust_organization.this[0].warp_auth_non_browser_401 == true
    )
    error_message = "Every boolean must reach the organization."
  }

  assert {
    condition = (
      cloudflare_zero_trust_organization.this[0].session_duration == "24h" &&
      cloudflare_zero_trust_organization.this[0].ui_read_only_toggle_reason == "Managed by Terraform" &&
      cloudflare_zero_trust_organization.this[0].user_seat_expiration_inactive_time == "730h" &&
      cloudflare_zero_trust_organization.this[0].warp_auth_session_duration == "24h"
    )
    error_message = "session_duration, ui_read_only_toggle_reason, user_seat_expiration_inactive_time and warp_auth_session_duration must reach the organization."
  }

  assert {
    condition     = cloudflare_zero_trust_organization.this[0].deny_unmatched_requests_exempted_zone_names == tolist(["example.net"])
    error_message = "deny_unmatched_requests_exempted_zone_names must reach the organization."
  }

  assert {
    condition = (
      cloudflare_zero_trust_organization.this[0].custom_pages == var.organization.custom_pages &&
      cloudflare_zero_trust_organization.this[0].login_design == var.organization.login_design &&
      cloudflare_zero_trust_organization.this[0].mfa_config == var.organization.mfa_config &&
      cloudflare_zero_trust_organization.this[0].mfa_piv_key_requirements == var.organization.mfa_piv_key_requirements &&
      cloudflare_zero_trust_organization.this[0].service_token_inactivity == var.organization.service_token_inactivity
    )
    error_message = "Every field of custom_pages, login_design, mfa_config, mfa_piv_key_requirements and service_token_inactivity must reach the organization."
  }
}
