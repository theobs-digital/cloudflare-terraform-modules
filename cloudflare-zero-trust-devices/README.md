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
it alone until you set it.

## Prerequisites

The version constraints are listed under [Requirements](#requirements). The
module is checked with provider 5.28.0 and Terraform 1.16.5.

The provider authenticates with an API token, read from the
`CLOUDFLARE_API_TOKEN` environment variable. The token needs these
permissions:

| Permission | Operations |
|---|---|
| Account → Zero Trust → Edit | device settings, default profile and its local domain fallback |
| Zone → SSL and Certificates → Edit | `default_profile_certificates`, on each zone it lists |

## Settings

`settings` manages the device settings of the account: Gateway proxy over TCP
and UDP, Cloudflare root certificate, CGNAT virtual IPs, override code time
limit and external emergency disconnect. The provider cannot import them, and the first apply writes them
with `PUT /accounts/{account_id}/devices/settings`: Cloudflare keeps the
fields the request leaves out.

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
  settings = {
    disable_for_time                      = 0
    gateway_proxy_enabled                 = true
    gateway_udp_proxy_enabled             = true
    root_certificate_installation_enabled = false
    use_zt_virtual_ip                     = true
  }
```

That organization had never set the `external_emergency_signal_*` fields,
and Cloudflare did not return them.

Removing `settings` destroys `cloudflare_zero_trust_device_settings`: the
provider calls `DELETE /accounts/{account_id}/devices/settings`, which resets
the device settings. On 17 October 2026, the reset set
`disable_for_time = 0`, `gateway_udp_proxy_enabled = true`,
`root_certificate_installation_enabled = false` and `use_zt_virtual_ip = true`
whatever they were before; `gateway_proxy_enabled`, `true` before, stayed
`true`. These are the values of the block above. To stop managing the
settings and keep their values, forget them first:

```bash
terraform state rm 'module.devices.cloudflare_zero_trust_device_settings.this[0]'
```

## Default profile

`default_profile` manages the default device profile, the one that applies
to devices no custom profile matches. It always exists, so the module never
creates it: adopt it with an `import` block, whose ID is the account ID.

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
  default_profile = {
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
`virtual_network_ids` output of the `cloudflare-zero-trust-networks` module;
`default` must be one of `allowed`. `global_acceleration` only works once
Cloudflare has turned it on for the account, through your account team: it is
tested with a mock provider only.

The ID of the resource is the account ID. The profile also has a
`policy_id`, which the module does not output.

Removing `default_profile` only drops the profile from the state: the apply
sends no request, and Cloudflare keeps the profile as last applied. The plan
warns about "Resource Destruction Considerations", as it does when it creates
the profile without `import`; the warning is harmless.

## Local domain fallback

`default_profile_local_domain_fallback` lists the domains that devices on the
default profile resolve with their local DNS, outside Gateway. `domains` is
the whole list: each apply replaces it, and a domain left out is removed.
Adopt the list with an `import` block, whose ID is the account ID, like the
default profile. The order of `domains` does not count.

The organization tested on 17 October 2026 held the 14 domains Cloudflare
recommends by default. With them in `domains`, the import planned no change:

```hcl
  default_profile_local_domain_fallback = {
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

Removing `default_profile_local_domain_fallback` only drops the list from the
state: the apply sends no request, and Cloudflare keeps the domains as last
applied.

## Device certificates

`default_profile_certificates` turns on, for each zone it lists, the client
certificate that WARP installs on devices for mTLS. Each entry takes a key of
your choice, so a zone created in the same configuration, whose ID is unknown
until apply, can still be listed:

```hcl
  default_profile_certificates = {
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
| [cloudflare_zero_trust_device_default_profile.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile) | resource |
| [cloudflare_zero_trust_device_default_profile_certificates.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile_certificates) | resource |
| [cloudflare_zero_trust_device_default_profile_local_domain_fallback.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_default_profile_local_domain_fallback) | resource |
| [cloudflare_zero_trust_device_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_settings) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the Zero Trust organization. | `string` | n/a | yes |
| <a name="input_default_profile"></a> [default\_profile](#input\_default\_profile) | Default device profile of the account, with the attributes of `cloudflare_zero_trust_device_default_profile` under the same names. When `null`, the module leaves it alone. Adopt it with an `import` block: without one, the first apply writes the provider default of each attribute left out, such as `tunnel_protocol = ""`. Write `exclude` or `include`, `service_mode_v2` and `dns_search_suffixes` as Cloudflare holds them, or each plan shows an empty update. Removing this argument changes nothing in Cloudflare, see [Default profile](#default-profile). | <pre>object({<br/>    allow_mode_switch     = optional(bool)<br/>    allow_updates         = optional(bool)<br/>    allowed_to_leave      = optional(bool)<br/>    auto_connect          = optional(number)<br/>    captive_portal        = optional(number)<br/>    disable_auto_fallback = optional(bool)<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    exclude_office_ips = optional(bool)<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    support_url          = optional(string)<br/>    switch_locked        = optional(bool)<br/>    tunnel_protocol      = optional(string)<br/>    uninstall_protection = optional(bool)<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_default_profile_certificates"></a> [default\_profile\_certificates](#input\_default\_profile\_certificates) | Device client certificates, one entry per zone, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_default_profile_certificates` under the same names. Removing an entry changes nothing in Cloudflare: apply `enabled = false` first to turn the certificate off, see [Device certificates](#device-certificates). | <pre>map(object({<br/>    enabled = bool<br/>    zone_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_default_profile_local_domain_fallback"></a> [default\_profile\_local\_domain\_fallback](#input\_default\_profile\_local\_domain\_fallback) | Local domain fallback of the default profile, with the attributes of `cloudflare_zero_trust_device_default_profile_local_domain_fallback` under the same names. When `null`, the module leaves it alone. `domains` replaces the whole list, Cloudflare's default domains included. Removing this argument changes nothing in Cloudflare, see [Local domain fallback](#local-domain-fallback). | <pre>object({<br/>    domains = set(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>      dns_server  = optional(list(string))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | Device settings of the account, with the attributes of `cloudflare_zero_trust_device_settings` under the same names. When `null`, the module leaves them alone. Write every field Cloudflare returns: one left out shows as a change to `null` at each plan, which Cloudflare refuses (error 2024). Removing this argument resets the settings, see [Settings](#settings). | <pre>object({<br/>    disable_for_time                      = optional(number)<br/>    external_emergency_signal_enabled     = optional(bool)<br/>    external_emergency_signal_fingerprint = optional(string)<br/>    external_emergency_signal_interval    = optional(string)<br/>    external_emergency_signal_url         = optional(string)<br/>    gateway_proxy_enabled                 = optional(bool)<br/>    gateway_udp_proxy_enabled             = optional(bool)<br/>    root_certificate_installation_enabled = optional(bool)<br/>    use_zt_virtual_ip                     = optional(bool)<br/>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
