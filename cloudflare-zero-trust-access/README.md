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

## Requirements

| | Version | Checked with |
|---|---|---|
| Terraform | `>= 1.3`, the first with optional object attributes | 1.3.10 and 1.16.5 |
| Provider [`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest) | `~> 5.28`, which renamed `mfa_ssh_piv_key_requirements` of the organization to `mfa_piv_key_requirements` | 5.28.0 |

The [import example](examples/import) needs Terraform 1.7 or later. The
provider reads its API token from the `CLOUDFLARE_API_TOKEN` environment
variable.

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
`name = ""`, or the plan renames it. An Entra ID provider returns
`conditional_access_enabled = false`: write it, or the plan sets it to `null`.

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

Terraform orders the work by input and by output, not by entry. Every entry
of an input waits for every object behind each output that one of its
entries refers to: when one of them fails, Terraform creates none of these
entries. A refused custom page holds back every application, even those
without it, and a refused application every short-lived certificate.

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
      include          = [{ email = { email = "sre@example.com" } }]
      connection_rules = { ssh = { usernames = ["root"] } }
    }]
  }
}
```

These policies take only some of the selectors, listed in Cloudflare's
[infrastructure policy selectors](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/non-http/infrastructure-apps/#infrastructure-policy-selectors):
`email`, `email_domain`, `saml`, `geo`, `auth_method`, `device_posture`,
`azure_ad`, `github_organization`, `gsuite` and `okta`. Cloudflare refuses
the others, an Access group included: "rule type 'group' not supported by
infrastructure apps" (code 12130).

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
`options_preflight_bypass`: write them as `false`. An `mcp` application
returns the last two as well, which the provider refuses for this type: the
plan sets them to `null`, applying it sends them so, and the next plan shows
no change.

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

## Tags and custom pages

Each entry of `access_tags` creates a tag, by the `name` of
[`cloudflare_zero_trust_access_tag`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_tag).
An application takes up to 25 tags in `tags`, by name, and users filter the
App Launcher by them. The name is also the tag's ID: renaming a tag replaces
it.

Cloudflare refuses an application with a tag that does not exist yet: "tags
must be created before assigning to an application" (code 12130). Refer to a
tag of the same call through the output `access_tag_ids`, so that Terraform
creates the tag first:

```hcl
access_tags = {
  hr = { name = "Human Resources" }
}

access_applications = {
  payroll = {
    name         = "Payroll"
    type         = "self_hosted"
    destinations = [{ type = "public", uri = "payroll.example.com" }]
    policies     = [{ id = module.access.access_policy_ids["staff"] }]
    tags         = [module.access.access_tag_ids["hr"]]
  }
}
```

Each entry of `access_custom_pages` takes the attributes of
[`cloudflare_zero_trust_access_custom_page`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_custom_page):
HTML that Access shows instead of its own page. `identity_denied` is shown to
a user who fails an identity rule, after login; `forbidden` to a user who
fails a non-identity rule, such as a country or a device posture, before
login. The API also accepts `login` and `interstitial`, which Cloudflare's
documentation does not describe. A `contract_version` of 1 or more marks a
Liquid template that Cloudflare sanitizes; without it, the page is served as
written. An application refers to its pages in
`custom_pages`, through the output `access_custom_page_ids`, and the
organization in `custom_pages.identity_denied` and `custom_pages.forbidden`.

Custom pages need a pay-as-you-go or Enterprise plan. On the Free plan,
Cloudflare refuses a page: "account does not have permission for custom
pages" (HTTP 403, code 12133). Custom pages are tested with mocks only.

While a custom page fails, Terraform creates none of the applications, even
those without it, see [Refer to other objects](#refer-to-other-objects).

Import a tag by its name, and a custom page by its ID, both prefixed with the
account:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_tag.this["hr"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/Human Resources"
}

import {
  to = module.access.cloudflare_zero_trust_access_custom_page.this["denied"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
}
```

The plan of an imported tag shows no change.

## Signing keys

`access_key_configuration` sets how often Cloudflare rotates the keys that sign
Access tokens: `key_rotation_interval_days`, from 21 to 365, which the
provider checks at plan; Cloudflare's default is 42 days. When it is `null`,
the module leaves the setting alone. Origins that check the signature of the
token must fetch the keys from
`https://<team>.cloudflareaccess.com/cdn-cgi/access/certs` rather than pin
them: Cloudflare keeps the previous key valid for 7 days after a rotation.
Terraform does not rotate the keys on demand: that is
`POST /accounts/<account>/access/keys/rotate`.

The provider's create updates the setting of the account, and its destroy
only drops it from the state: removing `access_key_configuration` leaves the
last interval applied. Both warn about "Resource Destruction
Considerations"; the warning is harmless. Import the setting by account ID,
and write the interval it has; the plan then shows no change:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_key_configuration.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

## Infrastructure targets

Each entry of `access_infrastructure_targets` takes the attributes of
[`cloudflare_zero_trust_access_infrastructure_target`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_infrastructure_target):
a server that `infrastructure` applications reach over SSH. `hostname` names
the target for Access only: it is not resolved, and several targets can share
it. `ip` gives its IPv4 or IPv6 address, or both, each in a virtual network:
`virtual_network_id` takes the ID of a virtual network, such as
`cloudflare_zero_trust_tunnel_cloudflared_virtual_network.x.id`; left out,
Cloudflare takes the account's default virtual network. An address belongs to
one target only within a virtual network. Cloudflare accepts an address that
no tunnel route covers yet.

`tags` labels the target with key-value pairs, one value per key, which the
`target_criteria` of an application match. They are not the Access tags
above. An application selects its targets by `hostname` or `tags`, not by ID,
so it does not depend on them:

```hcl
access_infrastructure_targets = {
  db1 = {
    hostname = "db-1"
    ip       = { ipv4 = { ip_addr = "10.0.0.11", virtual_network_id = var.virtual_network_id } }
    tags     = { environment = "production" }
  }
}
```

and, in an `infrastructure` application,
`include = { tags = { environment = ["production"] } }`.

Import a target by its ID, prefixed with the account; the plan shows no
change:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_infrastructure_target.this["db1"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/0e1f2a3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b"
}
```

## MCP servers and portals

Each entry of `access_ai_controls_mcp_servers` takes the attributes of
[`cloudflare_zero_trust_access_ai_controls_mcp_server`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_ai_controls_mcp_server):
an MCP server reached over HTTP, by the full URL of its endpoint in
`hostname`, such as `https://docs.mcp.cloudflare.com/mcp`. `auth_type` is
`unauthenticated`, `bearer`, with the token or a JSON object of headers in
`auth_credentials`, or `oauth`. Cloudflare connects to the server when it
creates it: a server it cannot reach is still created, in status `error`.

`id` is yours, and prefixes the name of each tool and prompt the server
exposes through a portal, as `<id>_<tool>`. The portal splits that name at the
first underscore: use hyphens in `id`, not underscores. Changing `id`,
`auth_type` or `hostname` replaces the server.

Cloudflare never returns `auth_credentials` and `client_secret`, which are
sensitive. After an import, the plan shows them as an update: applying sends
them again, and the next plan shows no change. This was checked with a bearer
token.

Each entry of `access_ai_controls_mcp_portals` takes the attributes of
[`cloudflare_zero_trust_access_ai_controls_mcp_portal`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_ai_controls_mcp_portal),
but the deprecated `allow_code_mode`: a single MCP endpoint, on `hostname` in
a zone of the account, for the servers of `servers`. `code_mode` defaults to
`opt_in`. `on_behalf` defaults to `true`, each user authorizing the server
with their own credentials; set it to `false` to use the server's admin
credential, which service tokens need.

Unlike the dashboard, the API creates neither the DNS record of the portal
nor its Access applications. Create a proxied CNAME record from the portal's
hostname to `gateway.agents.cloudflare.com`, such as with the
[cloudflare-dns](../cloudflare-dns/README.md) module, or the portal answers
with errors 522. Declare an `mcp_portal` application on the portal's hostname,
and an `mcp` application per server, with the policies of its users:

```hcl
access_ai_controls_mcp_servers = {
  docs = {
    id        = "docs"
    name      = "Cloudflare docs"
    hostname  = "https://docs.mcp.cloudflare.com/mcp"
    auth_type = "unauthenticated"
  }
}

access_ai_controls_mcp_portals = {
  main = {
    id       = "main"
    name     = "MCP"
    hostname = "mcp.example.com"
    servers  = [{ server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
  }
}

access_applications = {
  mcp_portal = {
    name         = "MCP"
    type         = "mcp_portal"
    destinations = [{ type = "public", uri = "mcp.example.com" }]
    policies     = [{ id = module.access.access_policy_ids["staff"] }]
  }
  mcp_docs = {
    name         = "Cloudflare docs"
    type         = "mcp"
    destinations = [{ type = "via_mcp_server_portal", mcp_server_id = module.access.access_ai_controls_mcp_server_ids["docs"] }]
    policies     = [{ id = module.access.access_policy_ids["staff"] }]
  }
}
```

The Free plan accepts servers, portals and both applications.

Import a server or a portal by its `id`, prefixed with the account; the plan
of a portal shows no change:

```hcl
import {
  to = module.access.cloudflare_zero_trust_access_ai_controls_mcp_portal.this["main"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/main"
}
```

## Reference

<details>
<summary><b>Every input and output, with its full type</b> (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
### Resources

The following resources are used by this module:

- [cloudflare_zero_trust_access_ai_controls_mcp_portal.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_ai_controls_mcp_portal) (resource)
- [cloudflare_zero_trust_access_ai_controls_mcp_server.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_ai_controls_mcp_server) (resource)
- [cloudflare_zero_trust_access_application.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_application) (resource)
- [cloudflare_zero_trust_access_custom_page.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_custom_page) (resource)
- [cloudflare_zero_trust_access_group.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_group) (resource)
- [cloudflare_zero_trust_access_identity_provider.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) (resource)
- [cloudflare_zero_trust_access_infrastructure_target.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_infrastructure_target) (resource)
- [cloudflare_zero_trust_access_key_configuration.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_key_configuration) (resource)
- [cloudflare_zero_trust_access_mtls_certificate.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_certificate) (resource)
- [cloudflare_zero_trust_access_mtls_hostname_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_hostname_settings) (resource)
- [cloudflare_zero_trust_access_policy.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_policy) (resource)
- [cloudflare_zero_trust_access_service_token.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_service_token) (resource)
- [cloudflare_zero_trust_access_short_lived_certificate.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_short_lived_certificate) (resource)
- [cloudflare_zero_trust_access_tag.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_tag) (resource)
- [cloudflare_zero_trust_organization.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_organization) (resource)

### Required Inputs

The following input variables are required:

#### <a name="input_account_id"></a> [account\_id](#input\_account\_id)

Description: ID of the Cloudflare account that owns the Zero Trust organization and its Access objects. Changing it replaces every resource of the module.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_access_ai_controls_mcp_portals"></a> [access\_ai\_controls\_mcp\_portals](#input\_access\_ai\_controls\_mcp\_portals)

Description: MCP portals of AI controls, by a key of your choice. Each portal takes the attributes of `cloudflare_zero_trust_access_ai_controls_mcp_portal` under the same names, but the deprecated `allow_code_mode`, with an `id` of your choice: changing `id` replaces the portal. A portal refers to a server of the same call with `server_id = module.<name>.access_ai_controls_mcp_server_ids["<key>"]`. See [MCP servers and portals](#mcp-servers-and-portals).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_ai_controls_mcp_servers"></a> [access\_ai\_controls\_mcp\_servers](#input\_access\_ai\_controls\_mcp\_servers)

Description: MCP servers of AI controls, by a key of your choice. Each server takes the attributes of `cloudflare_zero_trust_access_ai_controls_mcp_server` under the same names, with an `id` of your choice. Changing `id`, `auth_type` or `hostname` replaces the server. Keep `auth_credentials` and `client_secret` out of versioned files. See [MCP servers and portals](#mcp-servers-and-portals).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_applications"></a> [access\_applications](#input\_access\_applications)

Description: Access applications, by a key of your choice. The key only names the application in the state: keep it stable, since renaming a key replaces the application. Each application takes the attributes of `cloudflare_zero_trust_access_application` under the same names; set `type` before any attribute specific to a type. `policies` refers to reusable policies by ID, such as `{ id = module.<name>.access_policy_ids["<key>"], precedence = 1 }`, except for an `infrastructure` application, which takes policies written inside it, with `connection_rules`. See [Applications](#applications).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_custom_pages"></a> [access\_custom\_pages](#input\_access\_custom\_pages)

Description: Custom pages of Access, by a key of your choice. The key only names the page in the state: keep it stable, since renaming a key replaces the page. Each page takes the attributes of `cloudflare_zero_trust_access_custom_page` under the same names. An application refers to a page with `custom_pages = [module.<name>.access_custom_page_ids["<key>"]]`. See [Tags and custom pages](#tags-and-custom-pages).

Type:

```hcl
map(object({
    custom_html      = string
    name             = string
    type             = string
    contract_version = optional(number)
  }))
```

Default: `{}`

#### <a name="input_access_groups"></a> [access\_groups](#input\_access\_groups)

Description: Access groups, by a key of your choice. The key only names the group in the state: keep it stable, since renaming a key replaces the group. Each group takes the attributes of `cloudflare_zero_trust_access_group` under the same names. Each rule of `include`, `exclude` and `require` sets one selector, such as `{ email_domain = { domain = "example.com" } }` or `{ everyone = {} }`. See [Groups and policies](#groups-and-policies).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_identity_providers"></a> [access\_identity\_providers](#input\_access\_identity\_providers)

Description: Identity providers, by a key of your choice. The key only names the provider in the state: keep it stable, since renaming a key replaces the provider. Each provider takes the attributes of `cloudflare_zero_trust_access_identity_provider` under the same names, with the fields of its `type` in `config`. Changing `type` replaces the provider. See [Identity providers](#identity-providers).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_infrastructure_targets"></a> [access\_infrastructure\_targets](#input\_access\_infrastructure\_targets)

Description: Infrastructure targets: the servers that `infrastructure` applications protect, by a key of your choice. The key only names the target in the state: keep it stable, since renaming a key replaces the target. Each target takes the attributes of `cloudflare_zero_trust_access_infrastructure_target` under the same names. See [Infrastructure targets](#infrastructure-targets).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_key_configuration"></a> [access\_key\_configuration](#input\_access\_key\_configuration)

Description: Rotation of the keys that sign Access tokens, with the attribute of `cloudflare_zero_trust_access_key_configuration`. When `null`, the module leaves it alone, and removing this argument resets nothing. See [Signing keys](#signing-keys).

Type:

```hcl
object({
    key_rotation_interval_days = number
  })
```

Default: `null`

#### <a name="input_access_mtls_certificates"></a> [access\_mtls\_certificates](#input\_access\_mtls\_certificates)

Description: mTLS certificates: the certificate authorities that sign the client certificates Access accepts, by a key of your choice. The key only names the certificate in the state: keep it stable, since renaming a key replaces the certificate. Each certificate takes the attributes of `cloudflare_zero_trust_access_mtls_certificate` under the same names, with the PEM of the CA in `certificate`. Changing `certificate` replaces it. See [mTLS](#mtls).

Type:

```hcl
map(object({
    certificate          = string
    name                 = string
    associated_hostnames = optional(set(string))
  }))
```

Default: `{}`

#### <a name="input_access_mtls_hostname_settings"></a> [access\_mtls\_hostname\_settings](#input\_access\_mtls\_hostname\_settings)

Description: mTLS settings of the account's hostnames, with the attributes of `cloudflare_zero_trust_access_mtls_hostname_settings` under the same names. When `null`, the module leaves them alone. `settings` replaces the whole list of the account, and removing this argument resets nothing. See [mTLS](#mtls).

Type:

```hcl
object({
    settings = list(object({
      china_network                 = bool
      client_certificate_forwarding = bool
      hostname                      = string
    }))
  })
```

Default: `null`

#### <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies)

Description: Reusable Access policies, by a key of your choice. The key only names the policy in the state: keep it stable, since renaming a key replaces the policy. Each policy takes the attributes of `cloudflare_zero_trust_access_policy` under the same names, with the rules of `access_groups`. Refer to a group of the module with `group = { id = module.<name>.access_group_ids["<key>"] }`. See [Groups and policies](#groups-and-policies).

Type:

```hcl
map(object({
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
```

Default: `{}`

#### <a name="input_access_service_tokens"></a> [access\_service\_tokens](#input\_access\_service\_tokens)

Description: Service tokens, by a key of your choice. The key only names the token in the state: keep it stable, since renaming a key replaces the token and its credentials. Each token takes the attributes of `cloudflare_zero_trust_access_service_token` under the same names. To rotate the secret, increment `client_secret_version` and set `previous_client_secret_expires_at`, together. See [Service tokens](#service-tokens).

Type:

```hcl
map(object({
    name                              = string
    client_secret_version             = optional(number)
    duration                          = optional(string)
    enabled                           = optional(bool)
    previous_client_secret_expires_at = optional(string)
  }))
```

Default: `{}`

#### <a name="input_access_short_lived_certificates"></a> [access\_short\_lived\_certificates](#input\_access\_short\_lived\_certificates)

Description: Short-lived certificate CAs, one per SSH application, by a key of your choice. Each takes the `app_id` of `cloudflare_zero_trust_access_short_lived_certificate`, such as `module.<name>.access_application_ids["<key>"]`. Changing `app_id` replaces the CA, and its public key. See [Short-lived certificates](#short-lived-certificates).

Type:

```hcl
map(object({
    app_id = string
  }))
```

Default: `{}`

#### <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags)

Description: Tags of Access applications, by a key of your choice. Each tag takes the `name` of `cloudflare_zero_trust_access_tag`, which is also its ID: changing it replaces the tag. An application of the same call refers to a tag with `tags = [module.<name>.access_tag_ids["<key>"]]`. See [Tags and custom pages](#tags-and-custom-pages).

Type:

```hcl
map(object({
    name = string
  }))
```

Default: `{}`

#### <a name="input_organization"></a> [organization](#input\_organization)

Description: Settings of the Zero Trust organization, with the attributes of `cloudflare_zero_trust_organization` under the same names. When `null`, the module leaves the organization alone. Terraform does not create the organization, and removing this argument resets nothing. The first apply resets the settings it leaves out: import the organization before, see [Organization](#organization).

Type:

```hcl
object({
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
```

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_access_ai_controls_mcp_server_ids"></a> [access\_ai\_controls\_mcp\_server\_ids](#output\_access\_ai\_controls\_mcp\_server\_ids)

Description: IDs of the MCP servers, by key of `access_ai_controls_mcp_servers`. A portal takes them in `servers[*].server_id`, an `mcp` application in `destinations[*].mcp_server_id`.

#### <a name="output_access_application_auds"></a> [access\_application\_auds](#output\_access\_application\_auds)

Description: Audience tags (AUD) of the Access applications, by key of `access_applications`. The origin checks the `aud` claim of the Access token against it.

#### <a name="output_access_application_ids"></a> [access\_application\_ids](#output\_access\_application\_ids)

Description: IDs of the Access applications, by key of `access_applications`.

#### <a name="output_access_application_saas_apps"></a> [access\_application\_saas\_apps](#output\_access\_application\_saas\_apps)

Description: SaaS settings of the Access applications, by key of `access_applications`, as the provider returns them, with what Cloudflare generates: `client_id` and `client_secret` (OIDC), `idp_entity_id`, `sso_endpoint` and `public_key` (SAML). `null` for an application without `saas_app`. Cloudflare returns `client_secret` only at creation, see [Outputs of an application](#outputs-of-an-application).

#### <a name="output_access_custom_page_ids"></a> [access\_custom\_page\_ids](#output\_access\_custom\_page\_ids)

Description: IDs of the custom pages, by key of `access_custom_pages`. An application takes them in `custom_pages`, the organization in `custom_pages.forbidden` and `custom_pages.identity_denied`.

#### <a name="output_access_group_ids"></a> [access\_group\_ids](#output\_access\_group\_ids)

Description: IDs of the Access groups, by key of `access_groups`.

#### <a name="output_access_identity_provider_ids"></a> [access\_identity\_provider\_ids](#output\_access\_identity\_provider\_ids)

Description: IDs of the identity providers, by key of `access_identity_providers`.

#### <a name="output_access_identity_provider_scim_configs"></a> [access\_identity\_provider\_scim\_configs](#output\_access\_identity\_provider\_scim\_configs)

Description: SCIM settings of the identity providers, by key of `access_identity_providers`, as the provider returns them. Give the identity provider `scim_base_url` and `secret`. Cloudflare returns `secret` only when SCIM is first enabled: a provider imported with SCIM on has none, see [SCIM](#scim).

#### <a name="output_access_infrastructure_target_ids"></a> [access\_infrastructure\_target\_ids](#output\_access\_infrastructure\_target\_ids)

Description: IDs of the infrastructure targets, by key of `access_infrastructure_targets`.

#### <a name="output_access_mtls_certificate_ids"></a> [access\_mtls\_certificate\_ids](#output\_access\_mtls\_certificate\_ids)

Description: IDs of the mTLS certificates, by key of `access_mtls_certificates`.

#### <a name="output_access_policy_ids"></a> [access\_policy\_ids](#output\_access\_policy\_ids)

Description: IDs of the reusable Access policies, by key of `access_policies`.

#### <a name="output_access_service_token_client_ids"></a> [access\_service\_token\_client\_ids](#output\_access\_service\_token\_client\_ids)

Description: Client IDs of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Id` header.

#### <a name="output_access_service_token_client_secrets"></a> [access\_service\_token\_client\_secrets](#output\_access\_service\_token\_client\_secrets)

Description: Client secrets of the service tokens, by key of `access_service_tokens`, sent in the `CF-Access-Client-Secret` header. Cloudflare returns a secret only at creation and rotation: an imported token has none, see [Service tokens](#service-tokens).

#### <a name="output_access_service_token_ids"></a> [access\_service\_token\_ids](#output\_access\_service\_token\_ids)

Description: IDs of the service tokens, by key of `access_service_tokens`. A rule `service_token` takes this ID as `token_id`.

#### <a name="output_access_short_lived_certificate_public_keys"></a> [access\_short\_lived\_certificate\_public\_keys](#output\_access\_short\_lived\_certificate\_public\_keys)

Description: Public keys of the short-lived certificate CAs, by key of `access_short_lived_certificates`. SSH servers trust it with `TrustedUserCAKeys`.

#### <a name="output_access_tag_ids"></a> [access\_tag\_ids](#output\_access\_tag\_ids)

Description: IDs of the tags, by key of `access_tags`: a tag's ID is its name. An application takes them in `tags`.
<!-- END_TF_DOCS -->

</details>

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
