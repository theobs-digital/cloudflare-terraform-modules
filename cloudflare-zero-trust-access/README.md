# cloudflare-zero-trust-access

Terraform module that manages Cloudflare Access, the access control of
Cloudflare One: the Zero Trust organization, identity providers, access
groups and reusable policies, applications, service tokens, mTLS
certificates and their hostname settings, short-lived SSH certificates,
tags, custom pages, the rotation of signing keys, infrastructure targets, and
the MCP servers and portals of AI controls, on top of the
`cloudflare/cloudflare` provider. Every provider attribute of these resources
that is not deprecated is available under the same name.

The module works at the account level: Access objects attached to a zone are
not covered. Applications take reusable policies, by ID and precedence; the
policies written inside an application, which Cloudflare calls legacy, are
not supported.

The module is not released yet. The first release will be tagged
`cloudflare-zero-trust-access/v1.0.0`, see the [CHANGELOG](CHANGELOG.md).

## Usage

```hcl
module "access" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-zero-trust-access?ref=cloudflare-zero-trust-access/v1.0.0"

  account_id = "023e105f4ecef8ad9ca31a8372d0c353"

  organization = {
    name             = "example.cloudflareaccess.com"
    auth_domain      = "example.cloudflareaccess.com"
    session_duration = "24h"

    deny_unmatched_requests                     = false
    deny_unmatched_requests_exempted_zone_names = []
  }

  access_identity_providers = {
    otp = { name = "One-time PIN", type = "onetimepin", config = {} }
    entra = {
      name = "Microsoft Entra ID"
      type = "azureAD"
      config = {
        client_id      = "4f2b7c1e-9d3a-4e8b-a6c5-1b2d3e4f5a6b"
        client_secret  = var.entra_client_secret
        directory_id   = "9b2a1c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
        support_groups = true
      }
    }
  }

  access_groups = {
    staff = {
      name    = "Staff"
      include = [{ email_domain = { domain = "example.com" } }]
      require = [{ login_method = { id = module.access.access_identity_provider_ids["entra"] } }]
    }
  }

  access_policies = {
    staff = {
      name             = "Staff"
      decision         = "allow"
      include          = [{ group = { id = module.access.access_group_ids["staff"] } }]
      exclude          = [{ geo = { country_code = "KP" } }]
      session_duration = "8h"
    }
  }
}
```

Adopt the organization with an `import` block before the first apply, see
[Organization](#organization). Keep secrets such as `client_secret` out of
versioned files: pass them through a sensitive variable, as above. Objects of
the module refer to each other through its outputs, see
[Refer to other objects](#refer-to-other-objects).

See the [repository README](../README.md#usage) for the SSH form of the
source and the versioning rules.

## Prerequisites

The version constraints are listed under [Requirements](#requirements). The
module is checked with provider 5.28.0, and with Terraform 1.16.5 and 1.3.10:
1.3 is the first version with optional object attributes. It needs
provider 5.28 or later, which renamed `mfa_ssh_piv_key_requirements` of the
organization to `mfa_piv_key_requirements`.

The provider authenticates with an API token, read from the
`CLOUDFLARE_API_TOKEN` environment variable.

## Organization

`organization` holds the settings of the account's Zero Trust organization.
When it is `null`, the module leaves the organization alone.

Terraform does not create the organization: create it in the Zero Trust
dashboard, which also picks the team name. The provider's create updates the
existing organization, and its destroy only drops it from the state: removing
`organization` leaves the last values applied. Both warn about "Resource
Destruction Considerations"; the warning is harmless.

### Adopt the organization

The first apply sends only the attributes of `organization`, plus `false`
for five booleans the provider defaults (`allow_authenticate_via_warp`,
`auto_redirect_to_identity`, `is_ui_read_only`, `mfa_required_for_all_apps`
and `warp_auth_non_browser_401`), and Cloudflare resets settings the request
leaves out, such as `session_duration`. Its plan shows none of this. Import
the organization first, by account ID, so that the plan shows each setting it
would change:

```hcl
import {
  to = module.access.cloudflare_zero_trust_organization.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

Then copy into `organization` each value the plan sets to `null`. An
organization left at its defaults returns `deny_unmatched_requests = false`
and `deny_unmatched_requests_exempted_zone_names = []`: write them, as in
[Usage](#usage). It also returns `service_token_inactivity` turned off, with
`action` and `inactivity_threshold_days` empty, which the provider refuses as
input since both are required. The plan then still shows
`service_token_inactivity` going to `null`, and `mfa_configuration_allowed`
as known after apply. Applying it leaves the organization as it was, and the
next plan shows no change.

Once the organization is managed, the plan shows what each change sends: a
setting removed from `organization` goes to `null`, or to `false` for the
five booleans above. `mfa_configuration_allowed`,
`strict_service_token_auth` and `ui_read_only_toggle_reason` are the
exception: left out, they keep their value.

## Identity providers

Each entry of `access_identity_providers` takes the attributes of
[`cloudflare_zero_trust_access_identity_provider`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider).
`config` gathers the fields of every `type`: set those of yours, listed in
Cloudflare's [identity provider guides](https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/).
A one-time PIN takes `config = {}`. The provider refuses at plan, not at
validate, these fields on another type:

| `type` | Fields of `config` for this type only |
|---|---|
| `azureAD` | `directory_id`, `conditional_access_enabled`, `support_groups`, `prompt` |
| `centrify` | `centrify_account`, `centrify_app_id` |
| `google-apps` | `apps_domain` |
| `oidc` | `auth_url`, `token_url`, `certs_url`, `scopes` |
| `okta` | `okta_account`, `authorization_server_id` |
| `onelogin` | `onelogin_account` |
| `pingone` | `ping_env_id` |
| `saml` | `issuer_url`, `sso_target_url`, `idp_public_certs`, `attributes`, `email_attribute_name`, `header_attributes`, `sign_request` |

Changing `type` replaces the provider, and so does renaming its key: its ID
changes, and every group, policy or application that refers to it must
follow. To rename a key, declare the move:

```hcl
moved {
  from = module.access.cloudflare_zero_trust_access_identity_provider.this["old"]
  to   = module.access.cloudflare_zero_trust_access_identity_provider.this["new"]
}
```

### Import an identity provider

Import a provider by its ID, prefixed with the account:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_identity_provider.this["otp"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
}
```

A one-time PIN set up from the dashboard can have an empty name: write
`name = ""`, or the plan renames it.

Cloudflare never returns `config.client_secret`. After an import, the plan
shows the secret as an update: applying sends it again, and the next plan
shows no change.

### SCIM

With `scim_config.enabled = true`, Cloudflare generates the SCIM secret. Give
the identity provider `scim_base_url` and `secret`, from the sensitive output
`access_identity_provider_scim_configs`, such as
`module.access.access_identity_provider_scim_configs["entra"].secret`.

Cloudflare returns the secret only when SCIM is first enabled, and the
provider keeps it in the state. A provider imported with SCIM on has no
secret there: refresh it through the API
(`/access/identity_providers/<ID>/refresh_scim_secret`), as the provider
documentation says, and give the new one to the identity provider.

## Groups and policies

Each entry of `access_groups` takes the attributes of
[`cloudflare_zero_trust_access_group`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group),
and each entry of `access_policies` those of
[`cloudflare_zero_trust_access_policy`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_policy).
Policies are reusable: applications refer to them by ID.

Both take the same rules. A user must match at least one rule of `include`,
every rule of `require`, and no rule of `exclude`. A group needs `include`.
Each rule sets a single selector, among the 26 of the provider, listed in
Cloudflare's [Access policy selectors](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/#selectors):
the provider refuses a rule with two at plan. `everyone`,
`any_valid_service_token` and `certificate` take no value: write
`everyone = {}`. A group keeps the order of its rules; a policy does not.

```hcl
include = [
  { email_domain = { domain = "example.com" } },
  { email = { email = "contractor@example.net" } },
]
exclude = [{ geo = { country_code = "KP" } }]
require = [{ device_posture = { integration_uid = var.warp_posture_rule_id } }]
```

`device_posture` takes the ID of a device posture rule
(`cloudflare_zero_trust_device_posture_rule`), despite its name and the
provider's description, which speak of an integration. Cloudflare accepts any
ID there without checking it.

As for identity providers, renaming the key of a group or a policy replaces
it: declare a `moved` block, see [Identity providers](#identity-providers).

### Refer to other objects

A rule refers to an object of the same module call through the module's
outputs, such as `group = { id = module.access.access_group_ids["staff"] }` or
`login_method = { id = module.access.access_identity_provider_ids["otp"] }`.

A group cannot include another group of the same call this way: the output
`access_group_ids` depends on every group, and Terraform reports a cycle.
Declare the inner group in a second call of the module, which gives its ID
through the same output:

```hcl
module "access_base_groups" {
  source     = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-zero-trust-access?ref=cloudflare-zero-trust-access/v1.0.0"
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"

  access_groups = {
    sre = { name = "SRE", include = [{ email = { email = "sre@example.com" } }] }
  }
}
```

and then `group = { id = module.access_base_groups.access_group_ids["sre"] }`
in the groups of the main call.

### Policy settings

`mfa_config` needs independent MFA turned on for the organization, with at
least one authenticator in `organization.mfa_config.allowed_authenticators`.
Otherwise Cloudflare refuses the policy, even with
`mfa_config = { mfa_disabled = true }` alone: "organization must have at least
one allowed authenticator configured when apps or policies have mfa_config".

`isolation_required = true` needs
[Cloudflare Browser Isolation](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/isolate-application/)
on the account. An account without it refuses the policy: "missing required
permission to enable isolation_required".

### Import a group or a policy

The import IDs differ: a group is prefixed with `accounts/`, a policy is not.

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_group.this["staff"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/aa0a4aab-672b-4bdb-bc33-a59f1130a11f"
}

import {
  to = module.access.cloudflare_zero_trust_access_policy.this["staff"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/f267e341-3a1b-4d2c-9e5f-6a7b8c9d0e1f"
}
```

A policy created in the dashboard returns `session_duration = "24h"`: write
it, or the plan sets it to `null`. The provider never reads `is_default` of a
group back: after an import, the plan shows it as an update if you set it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.28 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_zero_trust_access_group.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group) | resource |
| [cloudflare_zero_trust_access_identity_provider.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) | resource |
| [cloudflare_zero_trust_access_policy.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_policy) | resource |
| [cloudflare_zero_trust_organization.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_organization) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the Zero Trust organization and its Access objects. Changing it replaces every resource of the module. | `string` | n/a | yes |
| <a name="input_access_groups"></a> [access\_groups](#input\_access\_groups) | Access groups, by a key of your choice. The key only names the group in the state: keep it stable, since renaming a key replaces the group. Each group takes the attributes of `cloudflare_zero_trust_access_group` under the same names. Each rule of `include`, `exclude` and `require` sets one selector, such as `{ email_domain = { domain = "example.com" } }` or `{ everyone = {} }`. See [Groups and policies](#groups-and-policies). | <pre>map(object({<br/>    include = list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    }))<br/>    name = string<br/>    exclude = optional(list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    is_default = optional(bool)<br/>    require = optional(list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_access_identity_providers"></a> [access\_identity\_providers](#input\_access\_identity\_providers) | Identity providers, by a key of your choice. The key only names the provider in the state: keep it stable, since renaming a key replaces the provider. Each provider takes the attributes of `cloudflare_zero_trust_access_identity_provider` under the same names, with the fields of its `type` in `config`. Changing `type` replaces the provider. See [Identity providers](#identity-providers). | <pre>map(object({<br/>    config = object({<br/>      apps_domain                = optional(string)<br/>      attributes                 = optional(list(string))<br/>      auth_url                   = optional(string)<br/>      authorization_server_id    = optional(string)<br/>      centrify_account           = optional(string)<br/>      centrify_app_id            = optional(string)<br/>      certs_url                  = optional(string)<br/>      claims                     = optional(list(string))<br/>      client_id                  = optional(string)<br/>      client_secret              = optional(string)<br/>      conditional_access_enabled = optional(bool)<br/>      directory_id               = optional(string)<br/>      email_attribute_name       = optional(string)<br/>      email_claim_name           = optional(string)<br/>      enable_encryption          = optional(bool)<br/>      force_authn                = optional(bool)<br/>      header_attributes = optional(list(object({<br/>        attribute_name = optional(string)<br/>        header_name    = optional(string)<br/>      })))<br/>      idp_public_certs            = optional(list(string))<br/>      issuer_url                  = optional(string)<br/>      login_page_auto_prompt      = optional(bool)<br/>      max_sso_url_length          = optional(number)<br/>      okta_account                = optional(string)<br/>      onelogin_account            = optional(string)<br/>      ping_env_id                 = optional(string)<br/>      pkce_enabled                = optional(bool)<br/>      prompt                      = optional(string)<br/>      restrict_to_account_members = optional(bool)<br/>      scopes                      = optional(list(string))<br/>      sign_request                = optional(bool)<br/>      sso_target_url              = optional(string)<br/>      support_groups              = optional(bool)<br/>      token_url                   = optional(string)<br/>      use_login_hint              = optional(bool)<br/>    })<br/>    name                    = string<br/>    type                    = string<br/>    read_only               = optional(bool)<br/>    saml_certificate_set_id = optional(string)<br/>    scim_config = optional(object({<br/>      enabled                  = optional(bool)<br/>      identity_update_behavior = optional(string)<br/>      seat_deprovision         = optional(bool)<br/>      user_deprovision         = optional(bool)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | Reusable Access policies, by a key of your choice. The key only names the policy in the state: keep it stable, since renaming a key replaces the policy. Each policy takes the attributes of `cloudflare_zero_trust_access_policy` under the same names, with the rules of `access_groups`. Refer to a group of the module with `group = { id = module.<name>.access_group_ids["<key>"] }`. See [Groups and policies](#groups-and-policies). | <pre>map(object({<br/>    decision = string<br/>    name     = string<br/>    approval_groups = optional(set(object({<br/>      approvals_needed = number<br/>      email_addresses  = optional(list(string))<br/>      email_list_uuid  = optional(string)<br/>    })))<br/>    approval_required = optional(bool)<br/>    connection_rules = optional(object({<br/>      rdp = optional(object({<br/>        allowed_clipboard_local_to_remote_formats = optional(list(string))<br/>        allowed_clipboard_remote_to_local_formats = optional(list(string))<br/>      }))<br/>    }))<br/>    exclude = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    include = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    isolation_required = optional(bool)<br/>    mfa_config = optional(object({<br/>      allowed_authenticators = optional(list(string))<br/>      mfa_disabled           = optional(bool)<br/>      session_duration       = optional(string)<br/>    }))<br/>    purpose_justification_prompt   = optional(string)<br/>    purpose_justification_required = optional(bool)<br/>    require = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    session_duration = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | Settings of the Zero Trust organization, with the attributes of `cloudflare_zero_trust_organization` under the same names. When `null`, the module leaves the organization alone. Terraform does not create the organization, and removing this argument resets nothing. The first apply resets the settings it leaves out: import the organization before, see [Organization](#organization). | <pre>object({<br/>    allow_authenticate_via_warp = optional(bool)<br/>    auth_domain                 = optional(string)<br/>    auto_redirect_to_identity   = optional(bool)<br/>    custom_pages = optional(object({<br/>      forbidden       = optional(string)<br/>      identity_denied = optional(string)<br/>    }))<br/>    deny_unmatched_requests                     = optional(bool)<br/>    deny_unmatched_requests_exempted_zone_names = optional(list(string))<br/>    is_ui_read_only                             = optional(bool)<br/>    login_design = optional(object({<br/>      background_color = optional(string)<br/>      footer_text      = optional(string)<br/>      header_text      = optional(string)<br/>      logo_path        = optional(string)<br/>      text_color       = optional(string)<br/>    }))<br/>    mfa_config = optional(object({<br/>      allowed_authenticators        = optional(list(string))<br/>      amr_matching_session_duration = optional(string)<br/>      required_aaguids              = optional(string)<br/>      session_duration              = optional(string)<br/>    }))<br/>    mfa_configuration_allowed = optional(bool)<br/>    mfa_piv_key_requirements = optional(object({<br/>      pin_policy          = optional(string)<br/>      require_fips_device = optional(bool)<br/>      ssh_key_size        = optional(list(number))<br/>      ssh_key_type        = optional(list(string))<br/>      touch_policy        = optional(string)<br/>    }))<br/>    mfa_required_for_all_apps = optional(bool)<br/>    name                      = optional(string)<br/>    service_token_inactivity = optional(object({<br/>      action                    = string<br/>      enabled                   = bool<br/>      inactivity_threshold_days = number<br/>    }))<br/>    session_duration                   = optional(string)<br/>    strict_service_token_auth          = optional(bool)<br/>    ui_read_only_toggle_reason         = optional(string)<br/>    user_seat_expiration_inactive_time = optional(string)<br/>    warp_auth_non_browser_401          = optional(bool)<br/>    warp_auth_session_duration         = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_group_ids"></a> [access\_group\_ids](#output\_access\_group\_ids) | IDs of the Access groups, by key of `access_groups`. |
| <a name="output_access_identity_provider_ids"></a> [access\_identity\_provider\_ids](#output\_access\_identity\_provider\_ids) | IDs of the identity providers, by key of `access_identity_providers`. |
| <a name="output_access_identity_provider_scim_configs"></a> [access\_identity\_provider\_scim\_configs](#output\_access\_identity\_provider\_scim\_configs) | SCIM settings of the identity providers, by key of `access_identity_providers`, as the provider returns them. Give the identity provider `scim_base_url` and `secret`. Cloudflare returns `secret` only when SCIM is first enabled: a provider imported with SCIM on has none, see [SCIM](#scim). |
| <a name="output_access_policy_ids"></a> [access\_policy\_ids](#output\_access\_policy\_ids) | IDs of the reusable Access policies, by key of `access_policies`. |
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
