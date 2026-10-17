# cloudflare-zero-trust-devices

Terraform module that manages the devices of a Cloudflare Zero Trust
organization: the WARP client settings and device profiles, local domain
fallback, managed networks, device posture integrations and rules, client
version deployment groups, device IP profiles and subnets, on top of the
`cloudflare/cloudflare` provider.

The module is under development and has no release yet. Releases will be
tagged `cloudflare-zero-trust-devices/vX.Y.Z` and listed in the
[CHANGELOG](CHANGELOG.md).

Every provider attribute of these resources is available under the same name.
The account settings, the default profile and its local domain fallback are
singletons: each one is an object, `null` by default, and the module leaves
it alone until you set it. The other resources are maps by a key of your
choice: the key only names the object in the state, so keep it stable, since
renaming a key replaces the object. Each map has an output of IDs by the same
keys, such as `device_custom_profile_ids`.

## Prerequisites

The version constraints are listed under [Requirements](#requirements). The
module is checked with provider 5.28.0 and Terraform 1.16.5.

The provider authenticates with an API token, read from the
`CLOUDFLARE_API_TOKEN` environment variable. The token needs these
permissions:

| Permission | Operations |
|---|---|
| Account → Zero Trust → Edit | device settings, default and custom profiles, their local domain fallbacks, managed networks |
| Zone → SSL and Certificates → Edit | `device_default_profile_certificates`, on each zone it lists |

## Settings

`device_settings` manages the device settings of the account: Gateway proxy
over TCP and UDP, Cloudflare root certificate, CGNAT virtual IPs, override
code time limit and external emergency disconnect. The provider cannot import
them, and the first apply writes them with
`PUT /accounts/{account_id}/devices/settings`: Cloudflare keeps the fields
the request leaves out.

The provider then reads every field back. A field Cloudflare returns and the
configuration leaves out shows as a change to `null` at each plan, and
Cloudflare refuses the `null` with `invalid account settings request`
(error 2024): the apply fails without changing anything. Write every field
Cloudflare returns. Read them before the first apply:

```bash
curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/devices/settings" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

Cloudflare reported these values on 17 October 2026 for an organization on
the Free plan, and this block, applied to it, then planned no change:

```hcl
  device_settings = {
    disable_for_time                      = 0
    gateway_proxy_enabled                 = true
    gateway_udp_proxy_enabled             = true
    root_certificate_installation_enabled = false
    use_zt_virtual_ip                     = true
  }
```

That organization had never set the `external_emergency_signal_*` fields,
and Cloudflare did not return them.

Removing `device_settings` destroys `cloudflare_zero_trust_device_settings`:
the provider calls `DELETE /accounts/{account_id}/devices/settings`, which
resets the device settings. On 17 October 2026, the reset set
`disable_for_time = 0`, `gateway_udp_proxy_enabled = true`,
`root_certificate_installation_enabled = false` and `use_zt_virtual_ip = true`
whatever they were before; `gateway_proxy_enabled`, `true` before, stayed
`true`. These are the values of the block above. To stop managing the settings
and keep their values, forget them first:

```bash
terraform state rm 'module.devices.cloudflare_zero_trust_device_settings.this[0]'
```

## Default profile

`device_default_profile` manages the default device profile, the one that
applies to devices no custom profile matches. It always exists, so the module
never creates it: adopt it with an `import` block, whose ID is the account ID.

```hcl
import {
  to = module.devices.cloudflare_zero_trust_device_default_profile.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

Without `import`, the first apply writes the provider default of each
attribute below that the configuration leaves out, over the value Cloudflare
holds:

| Attribute | Provider default |
|---|---|
| `allow_mode_switch`, `allow_updates`, `disable_auto_fallback`, `exclude_office_ips`, `sccm_vpn_boundary_support`, `switch_locked`, `uninstall_protection` | `false` |
| `allowed_to_leave`, `register_interface_ip_with_dns` | `true` |
| `auto_connect` | `0` |
| `captive_portal` | `180` |
| `support_url`, `tunnel_protocol` | `""` |

After an import, the plan shows these defaults as changes wherever
Cloudflare holds another value: write that value. The organization tested on
17 October 2026 held `tunnel_protocol = "masque"`.

`exclude`, `include`, `service_mode_v2` and `dns_search_suffixes` keep
Cloudflare's value when left out. Write them anyway as Cloudflare holds them:
while one of them is left out and Cloudflare holds a value for it, each plan
shows the default profile updated in place, `policy_id` going to
`(known after apply)` and nothing else, and the apply sends an empty update.
To clear `dns_search_suffixes`, write `[]`: leaving it out keeps the current
suffixes. `include` and `exclude` cannot be set together.

On 17 October 2026, Cloudflare reported this default profile for an
organization on the Free plan, and with this block, the import planned no
change:

```hcl
  device_default_profile = {
    tunnel_protocol = "masque"
    service_mode_v2 = { mode = "warp" }
    exclude = [
      { address = "10.0.0.0/8" },
      { address = "100.64.0.0/10" },
      { address = "169.254.0.0/16", description = "DHCP Unspecified" },
      { address = "172.16.0.0/12" },
      { address = "192.0.0.0/24" },
      { address = "192.168.0.0/16" },
      { address = "224.0.0.0/24" },
      { address = "240.0.0.0/4" },
      { address = "255.255.255.255/32", description = "DHCP Broadcast" },
      { address = "fe80::/10", description = "IPv6 Link Local" },
      { address = "fd00::/8" },
      { address = "ff01::/16" },
      { address = "ff02::/16" },
      { address = "ff03::/16" },
      { address = "ff04::/16" },
      { address = "ff05::/16" },
    ]
  }
```

`virtual_networks` takes IDs of virtual networks, such as the
`tunnel_cloudflared_virtual_network_ids` output of the
`cloudflare-zero-trust-networks` module;
`default` must be one of `allowed`. `global_acceleration` only works once
Cloudflare has turned it on for the account, through your account team: it is
tested with a mock provider only.

The ID of the resource is the account ID. The profile also has a
`policy_id`, which the module does not output.

Removing `device_default_profile` only drops the profile from the state: the
apply sends no request, and Cloudflare keeps the profile as last applied. The
plan warns about "Resource Destruction Considerations", as it does when it
creates the profile without `import`; the warning is harmless.

## Local domain fallback

`device_default_profile_local_domain_fallback` lists the domains that devices
on the default profile resolve with their local DNS, outside Gateway.
`domains` is the whole list: each apply replaces it, and a domain left out is
removed. Adopt the list with an `import` block, whose ID is the account ID,
like the default profile. The order of `domains` does not count.

The organization tested on 17 October 2026 held the 14 domains Cloudflare
recommends by default. With them in `domains`, the import planned no change:

```hcl
  device_default_profile_local_domain_fallback = {
    domains = [for suffix in [
      "home.arpa", "intranet", "internal", "private", "localdomain", "domain", "lan",
      "home", "host", "corp", "local", "localhost", "invalid", "test",
    ] : { suffix = suffix }]
  }
```

The default profile returns these domains in `fallback_domains`. When an
apply changes both, the module updates the profile first. In the other order,
or in parallel, the profile update fails with "Provider produced inconsistent
result after apply", since its `fallback_domains` changed during the apply;
in parallel, Cloudflare also answers `policy was modified concurrently`
(error 2077), which the provider retries.

Removing `device_default_profile_local_domain_fallback` only drops the list
from the state: the apply sends no request, and Cloudflare keeps the domains
as last applied.

## Device certificates

`device_default_profile_certificates` turns on, for each zone it lists, the
client certificate that WARP installs on devices for mTLS. Each entry takes a
key of your choice, so a zone created in the same configuration, whose ID is
unknown until apply, can still be listed:

```hcl
  device_default_profile_certificates = {
    example = {
      zone_id = cloudflare_zone.example.id
      enabled = true
    }
  }
```

The provider cannot import this setting: the first apply writes `enabled`,
and the plan warns about "Resource Destruction Considerations"; the warning is
harmless. Removing an entry only drops it from the state: the apply sends no
request, and the zone keeps the setting as last applied. To turn the
certificate off, apply `enabled = false` before removing the entry.

## Custom profiles

`device_custom_profiles` manages custom device profiles. A profile takes the
attributes of the default profile, plus `name`, `description`, `enabled`,
`match`, `precedence`, `profile_type` and `browser_extension_config`.

```hcl
  device_custom_profiles = {
    engineering = {
      name       = "Engineering"
      match      = "identity.groups.name == \"Engineering\""
      precedence = 100
      exclude    = [{ address = "10.0.0.0/8" }]
    }
  }
```

Cloudflare requires `name`, `match` and `precedence` to create a profile,
although the provider marks `match` and `precedence` optional: without them,
the apply fails with `missing fields in policy` (error 2072).

`match` is a wirefilter expression on the identity of the user
(`identity.email`, `identity.groups.id`, `identity.groups.name`,
`identity.groups.email`, `identity.saml_attributes`,
`identity.service_token_uuid`), the device (`os.name`, `os.version`,
`device.tags`) or the managed network the device is on, by its name
(`network == "Office"`, see [Managed networks](#managed-networks)). A group
ID can come from the `access_group_ids` output of the
`cloudflare-zero-trust-access` module.

A device gets the first profile whose `match` is true, in increasing
`precedence`; the default profile comes last. Each `precedence` must be
unique among custom profiles at each request: Cloudflare refuses a value that
another profile holds with `policy precedence must be unique and positive for
non-default policies` (error 2070), on creation as on update. To reorder
profiles, move them to values that no profile holds yet. Swapping two values
in one apply fails on both profiles, which Terraform updates in parallel; the
failure is clean, and Cloudflare and the state keep the previous values. On
17 October 2026, moving two profiles from 901 and 902 to 1002 and 1001
reversed their order in one apply. Leave gaps between values, such as 100,
200 and 300, to insert a profile without moving the others.

As for the default profile, the first apply writes the provider default of
each attribute in this table that the configuration leaves out:

| Attribute | Provider default |
|---|---|
| `allow_mode_switch`, `allow_updates`, `disable_auto_fallback`, `exclude_office_ips`, `sccm_vpn_boundary_support`, `switch_locked`, `uninstall_protection` | `false` |
| `allowed_to_leave`, `enabled`, `register_interface_ip_with_dns` | `true` |
| `auto_connect` | `0` |
| `captive_portal` | `180` |
| `description`, `support_url` | `""` |
| `profile_type` | `"warp"` |

These are Cloudflare's values for a new profile, so a profile the module
creates plans no change afterwards. On 17 October 2026, Cloudflare gave a
profile created this way its 16 default split tunnel exclusions in `exclude`,
its 14 default local domain fallback domains, `service_mode_v2 = { mode =
"warp" }` and `tunnel_protocol = ""`, where the default profile of the same
organization held `"masque"`. Write `tunnel_protocol` to choose the protocol.

To adopt a profile created in the dashboard, use an `import` block, whose ID
is `<account_id>/<policy_id>`, and write the values that the plan shows
changing, as for the [default profile](#default-profile).

```hcl
import {
  to = module.devices.cloudflare_zero_trust_device_custom_profile.this["engineering"]
  id = "023e105f4ecef8ad9ca31a8372d0c353/f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
}
```

`profile_type` is set at creation: changing it replaces the profile, which
gets a new ID. A `browser_extension` profile takes `browser_extension_config`,
which a `warp` profile refuses. Cloudflare refused browser extension profiles
for the organization tested on 17 October 2026, on the Free plan (`browser
extension profiles are not enabled for this account`, error 2615): they are
tested with a mock provider only. `global_acceleration` is too, as for the
default profile.

The ID of a profile is its `policy_id`, which `device_custom_profile_ids`
gives by key, for `device_custom_profile_local_domain_fallbacks`. Removing an
entry deletes the profile in Cloudflare.

## Local domain fallback of custom profiles

`device_custom_profile_local_domain_fallbacks` lists, for a custom profile, the
domains that devices resolve with their local DNS, outside Gateway. Take
`policy_id` from the `device_custom_profile_ids` output:

```hcl
  device_custom_profile_local_domain_fallbacks = {
    engineering = {
      policy_id = module.devices.device_custom_profile_ids["engineering"]
      domains = [
        { suffix = "corp.example", dns_server = ["10.0.0.53"] },
        { suffix = "local" },
      ]
    }
  }
```

A new profile starts with Cloudflare's 14 default domains. As for the default
profile, `domains` is the whole list: each apply replaces it, a domain left
out is removed, and the order does not count. Adopt the list of an existing
profile with an `import` block, whose ID is `<account_id>/<policy_id>`, the
ID of the profile.

The profile returns these domains in `fallback_domains`, so the module
updates every custom profile before any local domain fallback. Written in
parallel, the profile update fails with "Provider produced inconsistent
result after apply" (`.fallback_domains: new element 1 has appeared`), and
Cloudflare answers some requests with `policy was modified concurrently`
(error 2077), which the provider retries: on 17 October 2026, three applies
out of four failed this way with a `policy_id` written literally, none once
the module ordered them. In return, a profile that fails to apply holds back
every local domain fallback of the apply.

Changing `policy_id` replaces the entry: the module writes the domains to the
new profile and leaves the former profile as it is. Removing an entry only
drops the list from the state: the apply sends no request, and the profile
keeps the domains as last applied. The plan warns about "Resource Destruction
Considerations", as it does when it creates the entry; the warning is
harmless.

## Managed networks

`device_managed_networks` declares the networks that the WARP client
recognizes by a TLS host: on a managed network, the client reaches
`config.tls_sockaddr`, a `host:port`, and checks its certificate against
`config.sha256`, the SHA-256 fingerprint of the certificate, or with the usual
certificate checks when `sha256` is empty.

```hcl
  device_managed_networks = {
    office = {
      name   = "Office"
      type   = "tls"
      config = { tls_sockaddr = "192.0.2.20:443" }
    }
  }
```

The module sends `sha256 = ""` when you leave it out: Cloudflare returns an
empty string for a network without fingerprint, and the `null` of the
provider would show a change at each plan, which the apply does not settle.
Tested on 17 October 2026: with `""`, creation, a fingerprint set and the
return to `""` each plan no change afterwards.

A custom profile matches a managed network by its name, in `match`
(`network == "Office"`). Cloudflare does not check the name: a profile that
names a network that does not exist, or no longer does, is accepted and
matches no device. Write both from the same value to keep them together:

```hcl
locals {
  office = "Office"
}

module "devices" {
  # ...

  device_managed_networks = {
    office = { name = local.office, type = "tls", config = { tls_sockaddr = "192.0.2.20:443" } }
  }

  device_custom_profiles = {
    office = { name = "Office", match = "network == \"${local.office}\"", precedence = 100 }
  }
}
```

Adopt an existing network with an `import` block, whose ID is
`<account_id>/<network_id>`. Removing an entry deletes the network in
Cloudflare.

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
| [cloudflare_zero_trust_device_custom_profile.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_custom_profile) | resource |
| [cloudflare_zero_trust_device_custom_profile_local_domain_fallback.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_custom_profile_local_domain_fallback) | resource |
| [cloudflare_zero_trust_device_default_profile.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile) | resource |
| [cloudflare_zero_trust_device_default_profile_certificates.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile_certificates) | resource |
| [cloudflare_zero_trust_device_default_profile_local_domain_fallback.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile_local_domain_fallback) | resource |
| [cloudflare_zero_trust_device_managed_networks.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_managed_networks) | resource |
| [cloudflare_zero_trust_device_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_settings) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the Zero Trust organization. | `string` | n/a | yes |
| <a name="input_device_custom_profile_local_domain_fallbacks"></a> [device\_custom\_profile\_local\_domain\_fallbacks](#input\_device\_custom\_profile\_local\_domain\_fallbacks) | Local domain fallbacks of custom profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile_local_domain_fallback` under the same names. Take `policy_id` from the `device_custom_profile_ids` output. `domains` replaces the whole list of the profile, Cloudflare's default domains included. Removing an entry changes nothing in Cloudflare, see [Local domain fallback of custom profiles](#local-domain-fallback-of-custom-profiles). | <pre>map(object({<br/>    domains = set(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>      dns_server  = optional(list(string))<br/>    }))<br/>    policy_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_custom_profiles"></a> [device\_custom\_profiles](#input\_device\_custom\_profiles) | Custom device profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile` under the same names. Cloudflare requires `match` and `precedence` to create a profile (error 2072), and refuses a `precedence` that another custom profile holds (error 2070): reorder through values no profile holds. Changing `profile_type` replaces the profile, see [Custom profiles](#custom-profiles). | <pre>map(object({<br/>    name              = string<br/>    allow_mode_switch = optional(bool)<br/>    allow_updates     = optional(bool)<br/>    allowed_to_leave  = optional(bool)<br/>    auto_connect      = optional(number)<br/>    browser_extension_config = optional(object({<br/>      proxy_control = string<br/>      proxy_enabled = bool<br/>    }))<br/>    captive_portal        = optional(number)<br/>    description           = optional(string)<br/>    disable_auto_fallback = optional(bool)<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    enabled = optional(bool)<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    exclude_office_ips = optional(bool)<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    match                          = optional(string)<br/>    precedence                     = optional(number)<br/>    profile_type                   = optional(string)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    support_url          = optional(string)<br/>    switch_locked        = optional(bool)<br/>    tunnel_protocol      = optional(string)<br/>    uninstall_protection = optional(bool)<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_device_default_profile"></a> [device\_default\_profile](#input\_device\_default\_profile) | Default device profile of the account, with the attributes of `cloudflare_zero_trust_device_default_profile` under the same names. When `null`, the module leaves it alone. Adopt it with an `import` block: without one, the first apply writes the provider default of each attribute left out, such as `tunnel_protocol = ""`. Write `exclude` or `include`, `service_mode_v2` and `dns_search_suffixes` as Cloudflare holds them, or each plan shows an empty update. Removing this argument changes nothing in Cloudflare, see [Default profile](#default-profile). | <pre>object({<br/>    allow_mode_switch     = optional(bool)<br/>    allow_updates         = optional(bool)<br/>    allowed_to_leave      = optional(bool)<br/>    auto_connect          = optional(number)<br/>    captive_portal        = optional(number)<br/>    disable_auto_fallback = optional(bool)<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    exclude_office_ips = optional(bool)<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    support_url          = optional(string)<br/>    switch_locked        = optional(bool)<br/>    tunnel_protocol      = optional(string)<br/>    uninstall_protection = optional(bool)<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_device_default_profile_certificates"></a> [device\_default\_profile\_certificates](#input\_device\_default\_profile\_certificates) | Device client certificates, one entry per zone, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_default_profile_certificates` under the same names. Removing an entry changes nothing in Cloudflare: apply `enabled = false` first to turn the certificate off, see [Device certificates](#device-certificates). | <pre>map(object({<br/>    enabled = bool<br/>    zone_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_default_profile_local_domain_fallback"></a> [device\_default\_profile\_local\_domain\_fallback](#input\_device\_default\_profile\_local\_domain\_fallback) | Local domain fallback of the default profile, with the attributes of `cloudflare_zero_trust_device_default_profile_local_domain_fallback` under the same names. When `null`, the module leaves it alone. `domains` replaces the whole list, Cloudflare's default domains included. Removing this argument changes nothing in Cloudflare, see [Local domain fallback](#local-domain-fallback). | <pre>object({<br/>    domains = set(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>      dns_server  = optional(list(string))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_device_managed_networks"></a> [device\_managed\_networks](#input\_device\_managed\_networks) | Managed networks, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_managed_networks` under the same names. `config.sha256` defaults to `""`, which Cloudflare returns for a network without fingerprint. Custom profiles match a network by its `name`, which Cloudflare does not check, see [Managed networks](#managed-networks). | <pre>map(object({<br/>    config = object({<br/>      tls_sockaddr = string<br/>      sha256       = optional(string, "")<br/>    })<br/>    name = string<br/>    type = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_settings"></a> [device\_settings](#input\_device\_settings) | Device settings of the account, with the attributes of `cloudflare_zero_trust_device_settings` under the same names. When `null`, the module leaves them alone. Write every field Cloudflare returns: one left out shows as a change to `null` at each plan, which Cloudflare refuses (error 2024). Removing this argument resets the settings, see [Settings](#settings). | <pre>object({<br/>    disable_for_time                      = optional(number)<br/>    external_emergency_signal_enabled     = optional(bool)<br/>    external_emergency_signal_fingerprint = optional(string)<br/>    external_emergency_signal_interval    = optional(string)<br/>    external_emergency_signal_url         = optional(string)<br/>    gateway_proxy_enabled                 = optional(bool)<br/>    gateway_udp_proxy_enabled             = optional(bool)<br/>    root_certificate_installation_enabled = optional(bool)<br/>    use_zt_virtual_ip                     = optional(bool)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_device_custom_profile_ids"></a> [device\_custom\_profile\_ids](#output\_device\_custom\_profile\_ids) | IDs of the custom profiles, by key of `device_custom_profiles`: the `policy_id` that `device_custom_profile_local_domain_fallbacks` takes. |
| <a name="output_device_custom_profile_local_domain_fallback_ids"></a> [device\_custom\_profile\_local\_domain\_fallback\_ids](#output\_device\_custom\_profile\_local\_domain\_fallback\_ids) | IDs of the local domain fallbacks of custom profiles, by key of `device_custom_profile_local_domain_fallbacks`. Each one is the ID of its profile. |
| <a name="output_device_managed_network_ids"></a> [device\_managed\_network\_ids](#output\_device\_managed\_network\_ids) | IDs of the managed networks, by key of `device_managed_networks`. |
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
