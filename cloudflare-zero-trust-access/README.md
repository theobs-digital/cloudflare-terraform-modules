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
not covered. Applications refer to reusable policies by ID, except
infrastructure applications, which only take policies written inside them.

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

  access_applications = {
    wiki = {
      name         = "Wiki"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "wiki.example.com" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
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

## Applications

Each entry of `access_applications` takes the attributes of
[`cloudflare_zero_trust_access_application`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application),
but `self_hosted_domains`, deprecated in favor of `destinations`.

Set `type`. Many attributes belong to a few types, and the provider refuses
them at plan, not at validate, when `type` is another one or is left out:

| Attribute | Types |
|---|---|
| `saas_app`, required for these types | `saas`, `dash_sso` |
| `destinations` | `self_hosted`, `ssh`, `vnc`, `rdp`, `mcp_portal`, `mcp` |
| `allow_iframe`, `cors_headers`, `enable_binding_cookie`, `http_only_cookie_attribute`, `options_preflight_bypass`, `path_cookie_attribute`, `read_service_tokens_from_header`, `same_site_cookie_attribute`, `service_auth_401_redirect`, `skip_interstitial` | `self_hosted`, `ssh`, `vnc`, `rdp`, `mcp_portal` |
| `mfa_config` | `self_hosted`, `ssh`, `vnc`, `rdp` |
| `allow_authenticate_via_warp` | `self_hosted`, `ssh`, `vnc`, `rdp`, `saas`, `dash_sso` |
| `app_launcher_visible` | `self_hosted`, `ssh`, `vnc`, `rdp`, `saas`, `bookmark` |
| `target_criteria` | `rdp`, `infrastructure` |
| `app_launcher_logo_url`, `bg_color`, `footer_links`, `header_bg_color`, `landing_page_design`, `skip_app_launcher_login_page` | `app_launcher` |
| `session_duration` | every type but `biso` and `bookmark` |

`destinations` lists what the application protects: public hostnames and
paths (`uri`), private networks (`cidr` or `hostname`, with `port_range`,
`l4_protocol` and the `vnet_id` of a virtual network), Workers (`worker_id`)
and, for an `mcp` application, MCP servers (`mcp_server_id`). `type` defaults
to `public`. Left out, `domain` takes the first public destination. The Free
plan accepts private destinations.

Cloudflare refuses a `custom_deny_message` that contains any of `,.!:@?-`.

`mfa_config` needs independent MFA turned on for the organization, as for
policies, see [Policy settings](#policy-settings).

As for identity providers, renaming the key of an application replaces it,
with a new ID and a new AUD: declare a `moved` block, see
[Identity providers](#identity-providers).

### Policies of an application

`policies` lists the policies that Access applies to the application, by
ascending `precedence`, unique within the application. The provider numbers
an entry without `precedence` after the previous one. Leaving `policies` out
sends an empty list: the application keeps no policy.

Every type but `infrastructure` takes reusable policies, by ID:

```hcl
policies = [
  { id = module.access.access_policy_ids["staff"], precedence = 1 },
  { id = module.access.access_policy_ids["contractors"], precedence = 2 },
]
```

An `infrastructure` application only takes policies written inside it, with
the rules of `access_policies` and the Unix users that may connect in
`connection_rules.ssh`. Cloudflare's API offers no reference for this type,
reusable policies have no `connection_rules.ssh`, and the provider refuses a
reference at plan: "connection_rules has to be set if type is
infrastructure".

```hcl
access_applications = {
  databases = {
    name = "Databases"
    type = "infrastructure"
    target_criteria = [{
      port     = 22
      protocol = "SSH"
      include  = { target_attributes = { hostname = ["db-1", "db-2"] } }
    }]
    policies = [{
      name             = "SRE"
      decision         = "allow"
      include          = [{ group = { id = module.access.access_group_ids["sre"] } }]
      connection_rules = { ssh = { usernames = ["root"] } }
    }]
  }
}
```

For the other types, Cloudflare calls a policy written inside an application
legacy: its documentation says that one cannot be added to a new application,
though the API still accepts it. Write reusable policies there. Cloudflare's
API describes reusable and written policies as mutually exclusive within an
application.

`target_criteria` selects the targets of an `infrastructure` or `rdp`
application. Use the rule format of provider 5.28: `include`, with optional
`require` and `exclude`, each by `target_attributes.hostname` or by `tags`.
The provider describes the top-level `target_attributes` map as deprecated,
without flagging it: it remains for applications that still use it, and
cannot be combined with the rule format.

### Linked application tokens

A rule `linked_app_token` accepts the tokens that an application issues, such
as an OIDC SaaS application, by the ID of that application. A policy with
such a rule cannot refer to an application of the same call if applications
of that call refer to the module's policies: `access_application_ids` and
`access_policy_ids` then depend on each other, and Terraform reports a cycle.
Declare that policy, and the applications that use it, in a second call:

```hcl
module "access_api" {
  source     = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-zero-trust-access?ref=cloudflare-zero-trust-access/v1.0.0"
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"

  access_policies = {
    client_tokens = {
      name     = "Client tokens"
      decision = "non_identity"
      include  = [{ linked_app_token = { app_uid = module.access.access_application_ids["client"] } }]
    }
  }

  access_applications = {
    api = {
      name         = "API"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "api.example.com" }]
      policies     = [{ id = module.access_api.access_policy_ids["client_tokens"] }]
    }
  }
}
```

### Outputs of an application

The origin of an application checks the `aud` claim of the Access token
against `access_application_auds`.

The sensitive output `access_application_saas_apps` gives what Cloudflare
generates for a `saas` application: `client_id`, `client_secret` and
`public_key` for OIDC, where `client_id` equals the AUD; `idp_entity_id`,
`sso_endpoint` and `public_key` for SAML. Cloudflare returns `client_secret`
only at creation, and the provider keeps it in the state: an application
imported has none.

### Import an application

Import an application by its ID, prefixed with `accounts/` and the account:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_application.this["wiki"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/8a52bbeb-8fe6-485c-b644-6b046f2ff283"
}
```

After an import, the plan sets to `null` the booleans that Cloudflare returns
as `false`, such as `auto_redirect_to_identity`, `enable_binding_cookie` and
`options_preflight_bypass`: write them as `false`.

An application with a legacy policy: refer to that policy by its ID, as to a
reusable one. The plan then shows no change, and updates keep the policy and
its ID. To manage it as a reusable policy instead, convert it with
`PUT /accounts/<account>/access/apps/<app>/policies/<policy>/make_reusable`,
then import it into `access_policies`.

An `infrastructure` application: the provider keeps only the ID of each
policy at import, and this type refuses a reference, so the plan shows each
policy as an update. Applying it sends the policies again: Cloudflare
replaces each with an identical one under a new ID, and the next plan shows
no change.

## Service tokens

Each entry of `access_service_tokens` takes the attributes of
[`cloudflare_zero_trust_access_service_token`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_service_token).
A service token lets a machine through Access: it sends the
`CF-Access-Client-Id` and `CF-Access-Client-Secret` headers, from the outputs
`access_service_token_client_ids` and `access_service_token_client_secrets`
(sensitive). The application needs a policy with the decision `non_identity`
(Service Auth) and a rule `service_token`, or `any_valid_service_token = {}`
for every token of the account. A policy can refer to a token of the same call:

```hcl
access_service_tokens = {
  ci = { name = "CI" }
}

access_policies = {
  ci = {
    name     = "CI"
    decision = "non_identity"
    include  = [{ service_token = { token_id = module.access.access_service_token_ids["ci"] } }]
  }
}
```

Cloudflare returns the secret only at creation and at rotation, and the
provider keeps it in the state.

### Expiration

A token expires after `duration`: one year (`8760h`) by default, never with
`forever`. Terraform does not renew it, and its plan shows nothing as the date
nears; Cloudflare's notification "Expiring Access Service Token" warns a week
before. Every update of a token, a rename included, sets its expiration again
to `duration` from the time of the update: the provider sends `duration` with
each update.

### Rotate the secret

Increment `client_secret_version` and set `previous_client_secret_expires_at`,
an RFC 3339 timestamp until which Cloudflare still accepts the previous
secret. The provider refuses one without the other. The client ID stays, and
`access_service_token_client_secrets` gives the new secret after the apply.
Keep both attributes afterwards, and increment the version again at the next
rotation.

```hcl
access_service_tokens = {
  ci = {
    name                              = "CI"
    client_secret_version             = 2
    previous_client_secret_expires_at = "2026-11-01T00:00:00Z"
  }
}
```

### Import a service token

Import a token by its ID, prefixed with `accounts/` and the account:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_service_token.this["ci"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/3537a672-e4d8-4d89-aab9-26cb622918a1"
}
```

The provider never reads `client_secret_version` back: after an import, the
plan shows it as an update, with `client_secret` known after apply. Applying
sends the version Cloudflare already has, which does not rotate the secret;
the expiration starts over from `duration`, and the next plan shows no change.
Cloudflare does not return the secret of an imported token:
`access_service_token_client_secrets` gives `null` for it until the next
rotation. For a token rotated before, write its current
`client_secret_version`, which the API returns, with
`previous_client_secret_expires_at`.

## mTLS

Each entry of `access_mtls_certificates` takes the attributes of
[`cloudflare_zero_trust_access_mtls_certificate`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_certificate):
the certificate authority that signs the client certificates, in PEM, with
the whole chain for an intermediate CA, and the `associated_hostnames` of the
Access applications that request a client certificate. Their policies accept
it with the rule `certificate = {}`, or `common_name`. See Cloudflare's
[mutual TLS guide](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/mutual-tls-authentication/)
for the requirements on the CA.

mTLS needs a pay-as-you-go or Enterprise plan. On the Free plan, Cloudflare
refuses a certificate, even on an account that has none: "maximum number of
certificates has been reached" (code 12130). Certificates are tested with
mocks and a local copy of the API only.

Changing `certificate` replaces the certificate. To destroy one, the provider
first empties its `associated_hostnames`.

### Hostname settings

`access_mtls_hostname_settings` holds the mTLS settings of the account's
hostnames: `china_network` requests client certificates in China, on a zone
with the China Network; `client_certificate_forwarding` forwards the client
certificate to the origin, in the `Cf-Client-Cert-Der-Base64` and
`Cf-Client-Cert-Sha256` headers. When it is `null`, the module leaves the
settings alone.

`settings` replaces the whole list of the account: list every hostname. The
provider's create updates the existing list, and its destroy only drops it
from the state: removing `access_mtls_hostname_settings` leaves the last
settings applied. Both warn about "Resource Destruction Considerations"; the
warning is harmless.

The provider never reads `settings` back: a change made outside Terraform
does not show in the plan. Import the list by account, prefixed with
`accounts/`:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_mtls_hostname_settings.this[0]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353"
}
```

After the import, the plan shows `settings` as an update; applying it sends
the list of the configuration, and the next plan shows no change.
The Free plan accepts the list, tried empty only.

### Import an mTLS certificate

Import a certificate by its ID, prefixed with `accounts/` and the account:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_mtls_certificate.this["corp"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
}
```

The provider cannot read `certificate` back, and warns "MTLS certificate not
imported": the plan then replaces the certificate, which drops it from its
hostnames until the new one is created. Do not apply it. Import with the
`terraform import` command instead, then add the PEM to the state by hand,
exactly as the configuration gives it:

```bash
terraform import 'module.access.cloudflare_zero_trust_access_mtls_certificate.this["corp"]' accounts/023e105f4ecef8ad9ca31a8372d0c353/f174e90a-fafe-4643-bbbc-4a0ed4fc8415
terraform state pull > state.json
# In state.json, set the instance's attributes.certificate to the PEM,
# and increment serial.
terraform state push state.json
```

The next plan shows no change. This was checked against a local copy of the
API, since the Free plan refuses certificates.

## Short-lived certificates

Each entry of `access_short_lived_certificates` creates the SSH certificate
authority of an application, by its `app_id`. Access signs short-lived
certificates for the users of that application, and the SSH server trusts
them through the CA's public key, from the output
`access_short_lived_certificate_public_keys`, set in `TrustedUserCAKeys`. An
entry can refer to an application of the same call:

```hcl
access_short_lived_certificates = {
  ssh = { app_id = module.access.access_application_ids["ssh"] }
}
```

Cloudflare calls this setup legacy, and recommends `infrastructure`
applications for new SSH deployments. Changing `app_id` replaces the CA, with
a new public key.

Import a CA by the ID of its application, prefixed with `accounts/` and the
account; the plan shows no change:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_short_lived_certificate.this["ssh"]
  id = "accounts/023e105f4ecef8ad9ca31a8372d0c353/5a794c35-d97c-4e72-aaa1-ad732a3d0cdd"
}
```

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
| [cloudflare_zero_trust_access_application.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application) | resource |
| [cloudflare_zero_trust_access_group.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group) | resource |
| [cloudflare_zero_trust_access_identity_provider.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) | resource |
| [cloudflare_zero_trust_access_mtls_certificate.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_certificate) | resource |
| [cloudflare_zero_trust_access_mtls_hostname_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_hostname_settings) | resource |
| [cloudflare_zero_trust_access_policy.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_policy) | resource |
| [cloudflare_zero_trust_access_service_token.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_service_token) | resource |
| [cloudflare_zero_trust_access_short_lived_certificate.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_short_lived_certificate) | resource |
| [cloudflare_zero_trust_organization.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_organization) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the Zero Trust organization and its Access objects. Changing it replaces every resource of the module. | `string` | n/a | yes |
| <a name="input_access_applications"></a> [access\_applications](#input\_access\_applications) | Access applications, by a key of your choice. The key only names the application in the state: keep it stable, since renaming a key replaces the application. Each application takes the attributes of `cloudflare_zero_trust_access_application` under the same names; set `type` before any attribute specific to a type. `policies` refers to reusable policies by ID, such as `{ id = module.<name>.access_policy_ids["<key>"], precedence = 1 }`, except for an `infrastructure` application, which takes policies written inside it, with `connection_rules`. See [Applications](#applications). | <pre>map(object({<br/>    allow_authenticate_via_warp = optional(bool)<br/>    allow_iframe                = optional(bool)<br/>    allowed_idps                = optional(set(string))<br/>    app_launcher_logo_url       = optional(string)<br/>    app_launcher_visible        = optional(bool)<br/>    auto_redirect_to_identity   = optional(bool)<br/>    bg_color                    = optional(string)<br/>    cors_headers = optional(object({<br/>      allow_all_headers = optional(bool)<br/>      allow_all_methods = optional(bool)<br/>      allow_all_origins = optional(bool)<br/>      allow_credentials = optional(bool)<br/>      allowed_headers   = optional(set(string))<br/>      allowed_methods   = optional(set(string))<br/>      allowed_origins   = optional(set(string))<br/>      max_age           = optional(number)<br/>    }))<br/>    custom_deny_message          = optional(string)<br/>    custom_deny_url              = optional(string)<br/>    custom_non_identity_deny_url = optional(string)<br/>    custom_pages                 = optional(list(string))<br/>    destinations = optional(list(object({<br/>      cidr          = optional(string)<br/>      hostname      = optional(string)<br/>      l4_protocol   = optional(string)<br/>      mcp_server_id = optional(string)<br/>      port_range    = optional(string)<br/>      type          = optional(string)<br/>      uri           = optional(string)<br/>      vnet_id       = optional(string)<br/>      worker_id     = optional(string)<br/>    })))<br/>    domain                = optional(string)<br/>    enable_binding_cookie = optional(bool)<br/>    footer_links = optional(list(object({<br/>      name = string<br/>      url  = string<br/>    })))<br/>    header_bg_color            = optional(string)<br/>    http_only_cookie_attribute = optional(bool)<br/>    landing_page_design = optional(object({<br/>      button_color      = optional(string)<br/>      button_text_color = optional(string)<br/>      image_url         = optional(string)<br/>      message           = optional(string)<br/>      title             = optional(string)<br/>    }))<br/>    logo_url = optional(string)<br/>    mfa_config = optional(object({<br/>      allowed_authenticators = optional(list(string))<br/>      mfa_disabled           = optional(bool)<br/>      session_duration       = optional(string)<br/>    }))<br/>    name = optional(string)<br/>    oauth_configuration = optional(object({<br/>      dynamic_client_registration = optional(object({<br/>        allow_any_on_localhost = optional(bool)<br/>        allow_any_on_loopback  = optional(bool)<br/>        allowed_uris           = optional(list(string))<br/>        enabled                = optional(bool)<br/>      }))<br/>      enabled = optional(bool)<br/>      grant = optional(object({<br/>        access_token_lifetime = optional(string)<br/>        session_duration      = optional(string)<br/>      }))<br/>    }))<br/>    options_preflight_bypass = optional(bool)<br/>    path_cookie_attribute    = optional(bool)<br/>    policies = optional(list(object({<br/>      connection_rules = optional(object({<br/>        rdp = optional(object({<br/>          allowed_clipboard_local_to_remote_formats = optional(list(string))<br/>          allowed_clipboard_remote_to_local_formats = optional(list(string))<br/>        }))<br/>        ssh = optional(object({<br/>          usernames         = list(string)<br/>          allow_email_alias = optional(bool)<br/>        }))<br/>      }))<br/>      decision = optional(string)<br/>      exclude = optional(set(object({<br/>        any_valid_service_token = optional(object({}))<br/>        auth_context = optional(object({<br/>          ac_id                = string<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        auth_method = optional(object({<br/>          auth_method = string<br/>        }))<br/>        azure_ad = optional(object({<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        certificate = optional(object({}))<br/>        common_name = optional(object({<br/>          common_name = string<br/>        }))<br/>        device_posture = optional(object({<br/>          integration_uid = string<br/>        }))<br/>        email = optional(object({<br/>          email = string<br/>        }))<br/>        email_domain = optional(object({<br/>          domain = string<br/>        }))<br/>        email_list = optional(object({<br/>          id = string<br/>        }))<br/>        everyone = optional(object({}))<br/>        external_evaluation = optional(object({<br/>          evaluate_url = string<br/>          keys_url     = string<br/>        }))<br/>        geo = optional(object({<br/>          country_code = string<br/>        }))<br/>        github_organization = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>          team                 = optional(string)<br/>        }))<br/>        group = optional(object({<br/>          id = string<br/>        }))<br/>        gsuite = optional(object({<br/>          email                = string<br/>          identity_provider_id = string<br/>        }))<br/>        ip = optional(object({<br/>          ip = string<br/>        }))<br/>        ip_list = optional(object({<br/>          id = string<br/>        }))<br/>        linked_app_token = optional(object({<br/>          app_uid = string<br/>        }))<br/>        login_method = optional(object({<br/>          id = string<br/>        }))<br/>        oidc = optional(object({<br/>          claim_name           = string<br/>          claim_value          = string<br/>          identity_provider_id = string<br/>        }))<br/>        okta = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>        }))<br/>        saml = optional(object({<br/>          attribute_name       = string<br/>          attribute_value      = string<br/>          identity_provider_id = string<br/>        }))<br/>        service_token = optional(object({<br/>          token_id = string<br/>        }))<br/>      })))<br/>      id = optional(string)<br/>      include = optional(set(object({<br/>        any_valid_service_token = optional(object({}))<br/>        auth_context = optional(object({<br/>          ac_id                = string<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        auth_method = optional(object({<br/>          auth_method = string<br/>        }))<br/>        azure_ad = optional(object({<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        certificate = optional(object({}))<br/>        common_name = optional(object({<br/>          common_name = string<br/>        }))<br/>        device_posture = optional(object({<br/>          integration_uid = string<br/>        }))<br/>        email = optional(object({<br/>          email = string<br/>        }))<br/>        email_domain = optional(object({<br/>          domain = string<br/>        }))<br/>        email_list = optional(object({<br/>          id = string<br/>        }))<br/>        everyone = optional(object({}))<br/>        external_evaluation = optional(object({<br/>          evaluate_url = string<br/>          keys_url     = string<br/>        }))<br/>        geo = optional(object({<br/>          country_code = string<br/>        }))<br/>        github_organization = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>          team                 = optional(string)<br/>        }))<br/>        group = optional(object({<br/>          id = string<br/>        }))<br/>        gsuite = optional(object({<br/>          email                = string<br/>          identity_provider_id = string<br/>        }))<br/>        ip = optional(object({<br/>          ip = string<br/>        }))<br/>        ip_list = optional(object({<br/>          id = string<br/>        }))<br/>        linked_app_token = optional(object({<br/>          app_uid = string<br/>        }))<br/>        login_method = optional(object({<br/>          id = string<br/>        }))<br/>        oidc = optional(object({<br/>          claim_name           = string<br/>          claim_value          = string<br/>          identity_provider_id = string<br/>        }))<br/>        okta = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>        }))<br/>        saml = optional(object({<br/>          attribute_name       = string<br/>          attribute_value      = string<br/>          identity_provider_id = string<br/>        }))<br/>        service_token = optional(object({<br/>          token_id = string<br/>        }))<br/>      })))<br/>      mfa_config = optional(object({<br/>        allowed_authenticators = optional(list(string))<br/>        mfa_disabled           = optional(bool)<br/>        session_duration       = optional(string)<br/>      }))<br/>      name       = optional(string)<br/>      precedence = optional(number)<br/>      require = optional(set(object({<br/>        any_valid_service_token = optional(object({}))<br/>        auth_context = optional(object({<br/>          ac_id                = string<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        auth_method = optional(object({<br/>          auth_method = string<br/>        }))<br/>        azure_ad = optional(object({<br/>          id                   = string<br/>          identity_provider_id = string<br/>        }))<br/>        certificate = optional(object({}))<br/>        common_name = optional(object({<br/>          common_name = string<br/>        }))<br/>        device_posture = optional(object({<br/>          integration_uid = string<br/>        }))<br/>        email = optional(object({<br/>          email = string<br/>        }))<br/>        email_domain = optional(object({<br/>          domain = string<br/>        }))<br/>        email_list = optional(object({<br/>          id = string<br/>        }))<br/>        everyone = optional(object({}))<br/>        external_evaluation = optional(object({<br/>          evaluate_url = string<br/>          keys_url     = string<br/>        }))<br/>        geo = optional(object({<br/>          country_code = string<br/>        }))<br/>        github_organization = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>          team                 = optional(string)<br/>        }))<br/>        group = optional(object({<br/>          id = string<br/>        }))<br/>        gsuite = optional(object({<br/>          email                = string<br/>          identity_provider_id = string<br/>        }))<br/>        ip = optional(object({<br/>          ip = string<br/>        }))<br/>        ip_list = optional(object({<br/>          id = string<br/>        }))<br/>        linked_app_token = optional(object({<br/>          app_uid = string<br/>        }))<br/>        login_method = optional(object({<br/>          id = string<br/>        }))<br/>        oidc = optional(object({<br/>          claim_name           = string<br/>          claim_value          = string<br/>          identity_provider_id = string<br/>        }))<br/>        okta = optional(object({<br/>          identity_provider_id = string<br/>          name                 = string<br/>        }))<br/>        saml = optional(object({<br/>          attribute_name       = string<br/>          attribute_value      = string<br/>          identity_provider_id = string<br/>        }))<br/>        service_token = optional(object({<br/>          token_id = string<br/>        }))<br/>      })))<br/>    })))<br/>    read_service_tokens_from_header = optional(string)<br/>    saas_app = optional(object({<br/>      access_token_lifetime            = optional(string)<br/>      allow_pkce_without_client_secret = optional(bool)<br/>      app_launcher_url                 = optional(string)<br/>      auth_type                        = optional(string)<br/>      consumer_service_url             = optional(string)<br/>      custom_attributes = optional(list(object({<br/>        friendly_name = optional(string)<br/>        name          = optional(string)<br/>        name_format   = optional(string)<br/>        required      = optional(bool)<br/>        source = optional(object({<br/>          name = optional(string)<br/>          name_by_idp = optional(list(object({<br/>            idp_id      = optional(string)<br/>            source_name = optional(string)<br/>          })))<br/>        }))<br/>      })))<br/>      custom_claims = optional(list(object({<br/>        name     = optional(string)<br/>        required = optional(bool)<br/>        scope    = optional(string)<br/>        source = optional(object({<br/>          name        = optional(string)<br/>          name_by_idp = optional(map(string))<br/>        }))<br/>      })))<br/>      default_relay_state = optional(string)<br/>      grant_types         = optional(list(string))<br/>      group_filter_regex  = optional(string)<br/>      hybrid_and_implicit_options = optional(object({<br/>        return_access_token_from_authorization_endpoint = optional(bool)<br/>        return_id_token_from_authorization_endpoint     = optional(bool)<br/>      }))<br/>      idp_entity_id             = optional(string)<br/>      name_id_format            = optional(string)<br/>      name_id_transform_jsonata = optional(string)<br/>      redirect_uris             = optional(list(string))<br/>      refresh_token_options = optional(object({<br/>        lifetime = optional(string)<br/>      }))<br/>      saml_attribute_transform_jsonata = optional(string)<br/>      scopes                           = optional(list(string))<br/>      sp_entity_id                     = optional(string)<br/>      sso_endpoint                     = optional(string)<br/>    }))<br/>    same_site_cookie_attribute = optional(string)<br/>    scim_config = optional(object({<br/>      idp_uid    = string<br/>      remote_uri = string<br/>      authentication = optional(object({<br/>        scheme            = string<br/>        authorization_url = optional(string)<br/>        client_id         = optional(string)<br/>        client_secret     = optional(string)<br/>        password          = optional(string)<br/>        scopes            = optional(list(string))<br/>        token             = optional(string)<br/>        token_url         = optional(string)<br/>        user              = optional(string)<br/>      }))<br/>      deactivate_on_delete = optional(bool)<br/>      enabled              = optional(bool)<br/>      mappings = optional(list(object({<br/>        schema  = string<br/>        enabled = optional(bool)<br/>        filter  = optional(string)<br/>        operations = optional(object({<br/>          create = optional(bool)<br/>          delete = optional(bool)<br/>          update = optional(bool)<br/>        }))<br/>        strictness        = optional(string)<br/>        transform_jsonata = optional(string)<br/>      })))<br/>    }))<br/>    service_auth_401_redirect    = optional(bool)<br/>    session_duration             = optional(string)<br/>    skip_app_launcher_login_page = optional(bool)<br/>    skip_interstitial            = optional(bool)<br/>    tags                         = optional(set(string))<br/>    target_criteria = optional(list(object({<br/>      port     = number<br/>      protocol = string<br/>      exclude = optional(object({<br/>        tags = optional(map(list(string)))<br/>        target_attributes = optional(object({<br/>          hostname = list(string)<br/>        }))<br/>      }))<br/>      include = optional(object({<br/>        tags = optional(map(list(string)))<br/>        target_attributes = optional(object({<br/>          hostname = list(string)<br/>        }))<br/>      }))<br/>      require = optional(object({<br/>        tags = optional(map(list(string)))<br/>        target_attributes = optional(object({<br/>          hostname = list(string)<br/>        }))<br/>      }))<br/>      target_attributes = optional(map(list(string)))<br/>    })))<br/>    type = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_access_groups"></a> [access\_groups](#input\_access\_groups) | Access groups, by a key of your choice. The key only names the group in the state: keep it stable, since renaming a key replaces the group. Each group takes the attributes of `cloudflare_zero_trust_access_group` under the same names. Each rule of `include`, `exclude` and `require` sets one selector, such as `{ email_domain = { domain = "example.com" } }` or `{ everyone = {} }`. See [Groups and policies](#groups-and-policies). | <pre>map(object({<br/>    include = list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    }))<br/>    name = string<br/>    exclude = optional(list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    is_default = optional(bool)<br/>    require = optional(list(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_access_identity_providers"></a> [access\_identity\_providers](#input\_access\_identity\_providers) | Identity providers, by a key of your choice. The key only names the provider in the state: keep it stable, since renaming a key replaces the provider. Each provider takes the attributes of `cloudflare_zero_trust_access_identity_provider` under the same names, with the fields of its `type` in `config`. Changing `type` replaces the provider. See [Identity providers](#identity-providers). | <pre>map(object({<br/>    config = object({<br/>      apps_domain                = optional(string)<br/>      attributes                 = optional(list(string))<br/>      auth_url                   = optional(string)<br/>      authorization_server_id    = optional(string)<br/>      centrify_account           = optional(string)<br/>      centrify_app_id            = optional(string)<br/>      certs_url                  = optional(string)<br/>      claims                     = optional(list(string))<br/>      client_id                  = optional(string)<br/>      client_secret              = optional(string)<br/>      conditional_access_enabled = optional(bool)<br/>      directory_id               = optional(string)<br/>      email_attribute_name       = optional(string)<br/>      email_claim_name           = optional(string)<br/>      enable_encryption          = optional(bool)<br/>      force_authn                = optional(bool)<br/>      header_attributes = optional(list(object({<br/>        attribute_name = optional(string)<br/>        header_name    = optional(string)<br/>      })))<br/>      idp_public_certs            = optional(list(string))<br/>      issuer_url                  = optional(string)<br/>      login_page_auto_prompt      = optional(bool)<br/>      max_sso_url_length          = optional(number)<br/>      okta_account                = optional(string)<br/>      onelogin_account            = optional(string)<br/>      ping_env_id                 = optional(string)<br/>      pkce_enabled                = optional(bool)<br/>      prompt                      = optional(string)<br/>      restrict_to_account_members = optional(bool)<br/>      scopes                      = optional(list(string))<br/>      sign_request                = optional(bool)<br/>      sso_target_url              = optional(string)<br/>      support_groups              = optional(bool)<br/>      token_url                   = optional(string)<br/>      use_login_hint              = optional(bool)<br/>    })<br/>    name                    = string<br/>    type                    = string<br/>    read_only               = optional(bool)<br/>    saml_certificate_set_id = optional(string)<br/>    scim_config = optional(object({<br/>      enabled                  = optional(bool)<br/>      identity_update_behavior = optional(string)<br/>      seat_deprovision         = optional(bool)<br/>      user_deprovision         = optional(bool)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_access_mtls_certificates"></a> [access\_mtls\_certificates](#input\_access\_mtls\_certificates) | mTLS certificates: the certificate authorities that sign the client certificates Access accepts, by a key of your choice. The key only names the certificate in the state: keep it stable, since renaming a key replaces the certificate. Each certificate takes the attributes of `cloudflare_zero_trust_access_mtls_certificate` under the same names, with the PEM of the CA in `certificate`. Changing `certificate` replaces it. See [mTLS](#mtls). | <pre>map(object({<br/>    certificate          = string<br/>    name                 = string<br/>    associated_hostnames = optional(set(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_access_mtls_hostname_settings"></a> [access\_mtls\_hostname\_settings](#input\_access\_mtls\_hostname\_settings) | mTLS settings of the account's hostnames, with the attributes of `cloudflare_zero_trust_access_mtls_hostname_settings` under the same names. When `null`, the module leaves them alone. `settings` replaces the whole list of the account, and removing this argument resets nothing. See [mTLS](#mtls). | <pre>object({<br/>    settings = list(object({<br/>      china_network                 = bool<br/>      client_certificate_forwarding = bool<br/>      hostname                      = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | Reusable Access policies, by a key of your choice. The key only names the policy in the state: keep it stable, since renaming a key replaces the policy. Each policy takes the attributes of `cloudflare_zero_trust_access_policy` under the same names, with the rules of `access_groups`. Refer to a group of the module with `group = { id = module.<name>.access_group_ids["<key>"] }`. See [Groups and policies](#groups-and-policies). | <pre>map(object({<br/>    decision = string<br/>    name     = string<br/>    approval_groups = optional(set(object({<br/>      approvals_needed = number<br/>      email_addresses  = optional(list(string))<br/>      email_list_uuid  = optional(string)<br/>    })))<br/>    approval_required = optional(bool)<br/>    connection_rules = optional(object({<br/>      rdp = optional(object({<br/>        allowed_clipboard_local_to_remote_formats = optional(list(string))<br/>        allowed_clipboard_remote_to_local_formats = optional(list(string))<br/>      }))<br/>    }))<br/>    exclude = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    include = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    isolation_required = optional(bool)<br/>    mfa_config = optional(object({<br/>      allowed_authenticators = optional(list(string))<br/>      mfa_disabled           = optional(bool)<br/>      session_duration       = optional(string)<br/>    }))<br/>    purpose_justification_prompt   = optional(string)<br/>    purpose_justification_required = optional(bool)<br/>    require = optional(set(object({<br/>      any_valid_service_token = optional(object({}))<br/>      auth_context = optional(object({<br/>        ac_id                = string<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      auth_method = optional(object({<br/>        auth_method = string<br/>      }))<br/>      azure_ad = optional(object({<br/>        id                   = string<br/>        identity_provider_id = string<br/>      }))<br/>      certificate = optional(object({}))<br/>      cloudflare_account_member = optional(object({<br/>        account_id = optional(string)<br/>      }))<br/>      common_name = optional(object({<br/>        common_name = string<br/>      }))<br/>      device_posture = optional(object({<br/>        integration_uid = string<br/>        account_id      = optional(string)<br/>      }))<br/>      email = optional(object({<br/>        email = string<br/>      }))<br/>      email_domain = optional(object({<br/>        domain = string<br/>      }))<br/>      email_list = optional(object({<br/>        id = string<br/>      }))<br/>      everyone = optional(object({}))<br/>      external_evaluation = optional(object({<br/>        evaluate_url = string<br/>        keys_url     = string<br/>      }))<br/>      geo = optional(object({<br/>        country_code = string<br/>      }))<br/>      github_organization = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>        team                 = optional(string)<br/>      }))<br/>      group = optional(object({<br/>        id = string<br/>      }))<br/>      gsuite = optional(object({<br/>        email                = string<br/>        identity_provider_id = string<br/>      }))<br/>      ip = optional(object({<br/>        ip = string<br/>      }))<br/>      ip_list = optional(object({<br/>        id = string<br/>      }))<br/>      linked_app_token = optional(object({<br/>        app_uid = string<br/>      }))<br/>      login_method = optional(object({<br/>        id = string<br/>      }))<br/>      oidc = optional(object({<br/>        claim_name           = string<br/>        claim_value          = string<br/>        identity_provider_id = string<br/>      }))<br/>      okta = optional(object({<br/>        identity_provider_id = string<br/>        name                 = string<br/>      }))<br/>      saml = optional(object({<br/>        attribute_name       = string<br/>        attribute_value      = string<br/>        identity_provider_id = string<br/>      }))<br/>      service_token = optional(object({<br/>        token_id = string<br/>      }))<br/>      user_risk_score = optional(object({<br/>        user_risk_score = list(string)<br/>      }))<br/>    })))<br/>    session_duration = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_access_service_tokens"></a> [access\_service\_tokens](#input\_access\_service\_tokens) | Service tokens, by a key of your choice. The key only names the token in the state: keep it stable, since renaming a key replaces the token and its credentials. Each token takes the attributes of `cloudflare_zero_trust_access_service_token` under the same names. To rotate the secret, increment `client_secret_version` and set `previous_client_secret_expires_at`, together. See [Service tokens](#service-tokens). | <pre>map(object({<br/>    name                              = string<br/>    client_secret_version             = optional(number)<br/>    duration                          = optional(string)<br/>    enabled                           = optional(bool)<br/>    previous_client_secret_expires_at = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_access_short_lived_certificates"></a> [access\_short\_lived\_certificates](#input\_access\_short\_lived\_certificates) | Short-lived certificate CAs, one per SSH application, by a key of your choice. Each takes the `app_id` of `cloudflare_zero_trust_access_short_lived_certificate`, such as `module.<name>.access_application_ids["<key>"]`. Changing `app_id` replaces the CA, and its public key. See [Short-lived certificates](#short-lived-certificates). | <pre>map(object({<br/>    app_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | Settings of the Zero Trust organization, with the attributes of `cloudflare_zero_trust_organization` under the same names. When `null`, the module leaves the organization alone. Terraform does not create the organization, and removing this argument resets nothing. The first apply resets the settings it leaves out: import the organization before, see [Organization](#organization). | <pre>object({<br/>    allow_authenticate_via_warp = optional(bool)<br/>    auth_domain                 = optional(string)<br/>    auto_redirect_to_identity   = optional(bool)<br/>    custom_pages = optional(object({<br/>      forbidden       = optional(string)<br/>      identity_denied = optional(string)<br/>    }))<br/>    deny_unmatched_requests                     = optional(bool)<br/>    deny_unmatched_requests_exempted_zone_names = optional(list(string))<br/>    is_ui_read_only                             = optional(bool)<br/>    login_design = optional(object({<br/>      background_color = optional(string)<br/>      footer_text      = optional(string)<br/>      header_text      = optional(string)<br/>      logo_path        = optional(string)<br/>      text_color       = optional(string)<br/>    }))<br/>    mfa_config = optional(object({<br/>      allowed_authenticators        = optional(list(string))<br/>      amr_matching_session_duration = optional(string)<br/>      required_aaguids              = optional(string)<br/>      session_duration              = optional(string)<br/>    }))<br/>    mfa_configuration_allowed = optional(bool)<br/>    mfa_piv_key_requirements = optional(object({<br/>      pin_policy          = optional(string)<br/>      require_fips_device = optional(bool)<br/>      ssh_key_size        = optional(list(number))<br/>      ssh_key_type        = optional(list(string))<br/>      touch_policy        = optional(string)<br/>    }))<br/>    mfa_required_for_all_apps = optional(bool)<br/>    name                      = optional(string)<br/>    service_token_inactivity = optional(object({<br/>      action                    = string<br/>      enabled                   = bool<br/>      inactivity_threshold_days = number<br/>    }))<br/>    session_duration                   = optional(string)<br/>    strict_service_token_auth          = optional(bool)<br/>    ui_read_only_toggle_reason         = optional(string)<br/>    user_seat_expiration_inactive_time = optional(string)<br/>    warp_auth_non_browser_401          = optional(bool)<br/>    warp_auth_session_duration         = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_application_auds"></a> [access\_application\_auds](#output\_access\_application\_auds) | Audience tags (AUD) of the Access applications, by key of `access_applications`. The origin checks the `aud` claim of the Access token against it. |
| <a name="output_access_application_ids"></a> [access\_application\_ids](#output\_access\_application\_ids) | IDs of the Access applications, by key of `access_applications`. |
| <a name="output_access_application_saas_apps"></a> [access\_application\_saas\_apps](#output\_access\_application\_saas\_apps) | SaaS settings of the Access applications, by key of `access_applications`, as the provider returns them, with what Cloudflare generates: `client_id` and `client_secret` (OIDC), `idp_entity_id`, `sso_endpoint` and `public_key` (SAML). `null` for an application without `saas_app`. Cloudflare returns `client_secret` only at creation, see [Outputs of an application](#outputs-of-an-application). |
| <a name="output_access_group_ids"></a> [access\_group\_ids](#output\_access\_group\_ids) | IDs of the Access groups, by key of `access_groups`. |
| <a name="output_access_identity_provider_ids"></a> [access\_identity\_provider\_ids](#output\_access\_identity\_provider\_ids) | IDs of the identity providers, by key of `access_identity_providers`. |
| <a name="output_access_identity_provider_scim_configs"></a> [access\_identity\_provider\_scim\_configs](#output\_access\_identity\_provider\_scim\_configs) | SCIM settings of the identity providers, by key of `access_identity_providers`, as the provider returns them. Give the identity provider `scim_base_url` and `secret`. Cloudflare returns `secret` only when SCIM is first enabled: a provider imported with SCIM on has none, see [SCIM](#scim). |
| <a name="output_access_mtls_certificate_ids"></a> [access\_mtls\_certificate\_ids](#output\_access\_mtls\_certificate\_ids) | IDs of the mTLS certificates, by key of `access_mtls_certificates`. |
| <a name="output_access_policy_ids"></a> [access\_policy\_ids](#output\_access\_policy\_ids) | IDs of the reusable Access policies, by key of `access_policies`. |
| <a name="output_access_service_token_client_ids"></a> [access\_service\_token\_client\_ids](#output\_access\_service\_token\_client\_ids) | Client IDs of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Id` header. |
| <a name="output_access_service_token_client_secrets"></a> [access\_service\_token\_client\_secrets](#output\_access\_service\_token\_client\_secrets) | Client secrets of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Secret` header. Cloudflare returns a secret only at creation and rotation: an imported token has none, see [Service tokens](#service-tokens). |
| <a name="output_access_service_token_ids"></a> [access\_service\_token\_ids](#output\_access\_service\_token\_ids) | IDs of the service tokens, by key of `access_service_tokens`. A rule `service_token` takes this ID as `token_id`. |
| <a name="output_access_short_lived_certificate_public_keys"></a> [access\_short\_lived\_certificate\_public\_keys](#output\_access\_short\_lived\_certificate\_public\_keys) | Public keys of the short-lived certificate CAs, by key of `access_short_lived_certificates`. SSH servers trust it with `TrustedUserCAKeys`. |
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
