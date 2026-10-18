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
| Account → Zero Trust → Edit | device settings, default and custom profiles, their local domain fallbacks, managed networks, posture integrations and rules, device IP profiles, deployment groups |
| Account → Cloudflare One Networks → Edit | `device_subnets` |
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

## Device posture integrations

`device_posture_integrations` connects the organization to a third-party
service, whose verdict on each device a posture rule of the same type checks:
`crowdstrike_s2s`, `intune`, `kolide`, `sentinelone_s2s`, `tanium_s2s`,
`uptycs`, `workspace_one`, or `custom_s2s` for a service of your own.
`interval` sets how often Cloudflare polls the service, such as `10m` or
`12h`, and `config` takes the fields that the service needs.

```hcl
variable "posture_access_client_secret" {
  type      = string
  sensitive = true
}

module "devices" {
  # ...

  device_posture_integrations = {
    posture_service = {
      name     = "Posture service"
      type     = "custom_s2s"
      interval = "10m"
      config = {
        api_url              = "https://posture.example/devices"
        access_client_id     = "88bf3b6d86161464f6509f7219099e57.access"
        access_client_secret = var.posture_access_client_secret
      }
    }
  }
}
```

Cloudflare checks the credentials when it creates the integration, and
creates nothing if the check fails. On 17 and 18 October 2026, made-up
CrowdStrike credentials failed with `Testing your CrowdStrike credentials
failed. CrowdStrike API returned an unexpected status code of 401` (error
2046). A `custom_s2s` integration failed with `invalid Access client ID`
for a made-up service token, and, with a real one, with `issue with api_url:
POST https://… could not lookup IP` for a URL that does not resolve:
Cloudflare calls `api_url` to create the integration, so the service must
answer first. The apply stops on the error, and neither Cloudflare nor the
state holds an integration. Integrations are therefore tested with a mock
provider only.

The provider marks `config.client_secret`, `config.client_key` and
`config.access_client_secret` sensitive, so the plan hides them even when
written literally. Pass them from a sensitive variable or a secret store,
never written in a versioned `.tf` file, and leave the map itself unmarked:
Terraform refuses `for_each` over a sensitive value (`Invalid for_each
argument`), so `sensitive()` around the whole map fails, while a sensitive
value inside it keeps its mark. The state holds the secrets in clear text, as
it does any attribute: protect the state backend.

The provider never reads `client_secret`, `client_key`, `customer_id`,
`access_client_id` and `access_client_secret` back from Cloudflare (provider
code, 5.28.0): a change made in the dashboard does not show in the plan, and
after an `import`, whose ID is `<account_id>/<integration_id>`, the first
plan shows them as an update, which sends them again. Removing an entry
deletes the integration in Cloudflare.

`device_posture_integration_ids` gives the ID of each integration, by key,
for `input.connection_id` of the rules that check it.

## Device posture rules

`device_posture_rules` declares the checks that Access and Gateway policies
can require of a device. `type` chooses the check, among the 23 that the
provider lists; `input` takes its fields, `match` the platforms it runs on,
and `schedule` how often the WARP client runs it.

```hcl
  device_posture_rules = {
    macos_version = {
      name     = "macOS 15 or later"
      type     = "os_version"
      schedule = "5m"
      match    = [{ platform = "mac" }]
      input    = { version = "15.0.0", operator = ">=" }
    }
    disk_encryption = {
      name     = "Disk encryption"
      type     = "disk_encryption"
      schedule = "5m"
      match    = [{ platform = "mac" }, { platform = "windows" }]
      input    = { require_all = true, check_disks = [] }
    }
    posture_score = {
      name     = "Posture score of 70 or more"
      type     = "custom_s2s"
      schedule = "5m"
      input = {
        connection_id = module.devices.device_posture_integration_ids["posture_service"]
        score         = 70
        operator      = ">="
      }
    }
  }
```

A rule that checks an integration takes its ID in `input.connection_id`, from
the `device_posture_integration_ids` output. A `serial_number` rule takes, in
`input.id`, the ID of a Gateway list of type `SERIAL`, from the `list_ids`
output of the `cloudflare-zero-trust-gateway` module. A
`client_certificate_v2` rule takes, in `input.certificate_id`, the ID of a
`cloudflare_mtls_certificate` that holds the CA; its `cn` and
`subject_alternative_names` accept the `${serial_number}` and `${hostname}`
variables of the WARP client, which HCL needs written `$${serial_number}`,
or Terraform reads them as its own interpolation.

On 18 October 2026, the module created and imported, with no change
afterwards, rules of the types `os_version` (macOS, Windows, Linux),
`firewall`, `disk_encryption`, `file`, `application`, `domain_joined`,
`warp`, `gateway`, `serial_number` and `client_certificate_v2`. The rules
that check an integration are tested with a mock provider only, as are their
integrations. These rules showed what follows.

Leave `input.operating_system` out. Cloudflare's API reference marks it
required for several types, but Cloudflare created an `os_version` rule
without it, and accepted rules of every type above without it. Written, it is
dropped: Cloudflare never returns it, and each plan shows it again as an
update, which the apply does not settle. `match` chooses the platforms.

Write `schedule`, as `5m` for Cloudflare's default. Cloudflare sets `5m`
when it is left out: the provider hides that value from the plan of a rule it
created, but an imported rule plans `schedule = "5m" -> null` until
`schedule` is written. `serial_number` and `application` rules are the
reverse: the provider drops `5m` at import, so the first plan shows a written
`schedule = "5m"` as an update, which changes nothing in Cloudflare. In the
same way, Cloudflare returns `check_disks = []` for a `disk_encryption` rule
without disks: write it so, or an imported rule plans `[] -> null`.

Each apply sends the whole rule, so a field removed from the configuration is
removed in Cloudflare: removing `expiration` cleared it. `description` is the
exception: the provider keeps the last value when it is left out, so
removing it changes nothing, in the plan or in Cloudflare. Write
`description = ""` to clear it.

Creating a Gateway list of type `SERIAL` also made Cloudflare create a
`serial_number` rule of the same ID and name as the list, outside Terraform;
deleting the list removed it. An organization may also hold rules named `WARP` and `Gateway`, of
the types `warp` and `gateway`, without input: the module imported both with
no change.

Adopt an existing rule with an `import` block, whose ID is
`<account_id>/<rule_id>`, and write the values that the plan shows changing.
Removing an entry deletes the rule in Cloudflare.

`device_posture_rule_ids` gives the ID of each rule, by key, for the
`device_posture` rules of Access groups and policies, and the
`device_posture.checks.passed` expressions of Gateway policies.

## Device IP profiles and subnets

A device gets its IPv4 address from a subnet of the account when it
registers. `device_subnets` declares subnets, and `device_ip_profiles` chooses
the subnet of each device: the first profile whose `match` is true, in
increasing `precedence`. A device keeps its address until it registers
again.
Cloudflare's documentation sets these conditions: client 2025.10.186.0 or
later on Windows, macOS or Linux, the global device setting *Assign a unique
IP address to each device*, and 30 IP profiles at most.

```hcl
  device_subnets = {
    engineering = { name = "Engineering", network = "10.80.0.0/16" }
  }

  device_ip_profiles = {
    engineering = {
      name       = "Engineering"
      match      = "identity.groups.name == \"Engineering\""
      precedence = 100
      subnet_id  = module.devices.device_subnet_ids["engineering"]
    }
  }
```

`network` is an IPv4 range of `/24` or larger within `10.0.0.0/8`,
`172.16.0.0/12`, `192.168.0.0/16` or `100.64.0.0/10`. On 18 October 2026,
Cloudflare refused a `/25` (`Subnet range is too small`, error 1098), a
public range and an IPv6 range (error 1090), and a range that overlaps
another subnet (`This subnet conflicts with other subnets or routes`, 409,
error 1027).

Cloudflare refuses to change the `network` of a subnet (`Operation "modify
IPv4 subnet" is not allowed`, error 1090), although the provider plans the
change as an update in place. Declare the new range under a new key instead,
move the IP profiles to it, and remove the old key, in the same apply.
Cloudflare refuses to delete a subnet that an IP profile uses (`Cannot delete
subnet because there are still references from IP profiles`, error 1121), so
the module creates subnets with `create_before_destroy`: Terraform then
updates the profiles before it deletes the old subnet. On 18 October 2026,
this apply went through, where the same apply without
`create_before_destroy` deleted the subnet first and failed. To rename the key
of a subnet, use a `moved` block: a new key creates the new subnet first, on
the same range, which Cloudflare refuses.

```hcl
moved {
  from = module.devices.cloudflare_zero_trust_device_subnet.this["eng"]
  to   = module.devices.cloudflare_zero_trust_device_subnet.this["engineering"]
}
```

The account holds one default subnet for each IP family, which Cloudflare
created with the organization. `is_default_network = true` moves the default
to another subnet: Cloudflare sets the former default to `false`, outside
Terraform. It refuses a change of the default subnet to `false` (`there must
always be a default subnet for each IP family and subnet type`, error 1094):
set `true` on another subnet instead. The organization tested on 18 October
2026 held these two default subnets of the `warp` type, which the module
imported with no change:

```hcl
  device_subnets = {
    default_ipv4 = {
      name               = "Subnet of CGNAT"
      network            = "100.96.0.0/12"
      comment            = "Default IPv4 subnet"
      is_default_network = true
    }
    default_ipv6 = {
      name               = "Default WARP Cloudflare One Subnet"
      network            = "2606:4700:cf1:1000::/64"
      is_default_network = true
    }
  }
```

Write `comment` and `is_default_network` as Cloudflare holds them: left out,
they take the provider defaults, `""` and `false`, which the plan shows as
changes. List the subnets of the account to find their IDs, names and
comments; the resource manages those of the `warp` type, not the
`cloudflare_source` and `initial_resolved_ip` ones that the list also holds:

```bash
curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/zerotrust/subnets" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

`match` of an IP profile is a wirefilter expression on the identity of the
user: `identity.email`, `identity.name`, `identity.groups.id`,
`identity.groups.name`, `identity.groups.email` and
`identity.saml_attributes`. Each `precedence` must be unique among IP
profiles (`IP profile precedence must be unique`, error 2808): reorder them
as custom profiles, through values that no profile holds. `enabled` is `true`
unless written.

Removing `description` from an IP profile keeps it in Cloudflare, which
ignores the `null` the provider sends, and each plan shows the removal again.
`description = ""` clears it; Cloudflare then returns no description, so
remove the line after that apply, or each plan shows `""` again.

Adopt an existing subnet or IP profile with an `import` block, whose ID is
`<account_id>/<subnet_id>` or `<account_id>/<profile_id>`. Removing an entry
deletes the subnet or the IP profile in Cloudflare.

## Deployment groups

`device_deployment_groups` sets the version of the WARP client on the devices
of some profiles: Cloudflare sends it to the Windows and macOS devices whose
profile is in `policy_ids`, and they install it themselves, from client
2026.6.0 on. Each entry of `version_config` gives a `target_environment`,
`windows` or `macos`, and the `version` to run there. Cloudflare's API marks
deployment groups as beta.

```hcl
  device_deployment_groups = {
    ring0 = {
      name = "Ring 0"
      version_config = [
        { target_environment = "windows", version = "2026.8.2110.0" },
        { target_environment = "macos", version = "2026.8.2110.0" },
      ]
      policy_ids = [module.devices.device_custom_profile_ids["it"]]
    }
  }
```

`version` is a full release number, as the
[client changelog](https://developers.cloudflare.com/cloudflare-one/changelog/cloudflare-one-client/)
lists them. On 18 October 2026, Cloudflare refused the short form
`2026.6.0` that its documentation shows (`invalid version format`,
error 2020), and a release that does not exist for the platform (`version
2026.6.234.0 not found for platform windows`, error 2030). It refused
`linux` (`target_environment must be macos or windows`, error 2905), and a
platform twice in one group (error 2902). It keeps `version_config` in the
order written.

`policy_ids` takes the IDs of custom profiles, from the
`device_custom_profile_ids` output, and the default profile, from
`device_default_profile_policy_id`. Cloudflare checks that they exist
(`one or more policies do not exist`, error 2902). The default profile's
policy ID is not the ID of its resource, which is the account ID: the output
gives it when `device_default_profile` is set. Write the default profile as
Cloudflare holds it, see [Default profile](#default-profile): when its plan
shows an empty update, its `policy_id` is unknown until the apply, and each
group that lists it shows an update too.

A profile belongs to one group at most: Cloudflare refuses a profile that
another group holds (`policy already assigned to another deployment group`,
409, error 2903). Terraform updates both groups at once when a profile moves
from one to the other; on 18 October 2026, moving a profile one way and back
in one apply worked 9 times out of 9.

Once a group holds profiles, it keeps at least one. Cloudflare refuses
`policy_ids = []` (`policy_ids cannot be an empty array`, error 2902), and
ignores the `null` that the provider sends for a `policy_ids` removed from the
configuration: the group keeps its profiles, and each plan shows the removal
again. To take its last profile out, give it another one, or remove the
group. A group created without `policy_ids` targets no device, and plans no
change.

Adopt an existing group with an `import` block, whose ID is
`<account_id>/<group_id>`: on 18 October 2026, two groups imported with no
change. Removing an entry deletes the group in Cloudflare.

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
| [cloudflare_zero_trust_device_deployment_groups.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_deployment_groups) | resource |
| [cloudflare_zero_trust_device_ip_profile.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_ip_profile) | resource |
| [cloudflare_zero_trust_device_managed_networks.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_managed_networks) | resource |
| [cloudflare_zero_trust_device_posture_integration.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_integration) | resource |
| [cloudflare_zero_trust_device_posture_rule.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_rule) | resource |
| [cloudflare_zero_trust_device_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_settings) | resource |
| [cloudflare_zero_trust_device_subnet.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the Zero Trust organization. | `string` | n/a | yes |
| <a name="input_device_custom_profile_local_domain_fallbacks"></a> [device\_custom\_profile\_local\_domain\_fallbacks](#input\_device\_custom\_profile\_local\_domain\_fallbacks) | Local domain fallbacks of custom profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile_local_domain_fallback` under the same names. Take `policy_id` from the `device_custom_profile_ids` output. `domains` replaces the whole list of the profile, Cloudflare's default domains included. Removing an entry changes nothing in Cloudflare, see [Local domain fallback of custom profiles](#local-domain-fallback-of-custom-profiles). | <pre>map(object({<br/>    domains = set(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>      dns_server  = optional(list(string))<br/>    }))<br/>    policy_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_custom_profiles"></a> [device\_custom\_profiles](#input\_device\_custom\_profiles) | Custom device profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_custom_profile` under the same names. Cloudflare requires `match` and `precedence` to create a profile (error 2072), and refuses a `precedence` that another custom profile holds (error 2070): reorder through values no profile holds. Changing `profile_type` replaces the profile, see [Custom profiles](#custom-profiles). | <pre>map(object({<br/>    name              = string<br/>    allow_mode_switch = optional(bool)<br/>    allow_updates     = optional(bool)<br/>    allowed_to_leave  = optional(bool)<br/>    auto_connect      = optional(number)<br/>    browser_extension_config = optional(object({<br/>      proxy_control = string<br/>      proxy_enabled = bool<br/>    }))<br/>    captive_portal        = optional(number)<br/>    description           = optional(string)<br/>    disable_auto_fallback = optional(bool)<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    enabled = optional(bool)<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    exclude_office_ips = optional(bool)<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    match                          = optional(string)<br/>    precedence                     = optional(number)<br/>    profile_type                   = optional(string)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    support_url          = optional(string)<br/>    switch_locked        = optional(bool)<br/>    tunnel_protocol      = optional(string)<br/>    uninstall_protection = optional(bool)<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_device_default_profile"></a> [device\_default\_profile](#input\_device\_default\_profile) | Default device profile of the account, with the attributes of `cloudflare_zero_trust_device_default_profile` under the same names. When `null`, the module leaves it alone. Adopt it with an `import` block: without one, the first apply writes the provider default of each attribute left out, such as `tunnel_protocol = ""`. Write `exclude` or `include`, `service_mode_v2` and `dns_search_suffixes` as Cloudflare holds them, or each plan shows an empty update. Removing this argument changes nothing in Cloudflare, see [Default profile](#default-profile). | <pre>object({<br/>    allow_mode_switch     = optional(bool)<br/>    allow_updates         = optional(bool)<br/>    allowed_to_leave      = optional(bool)<br/>    auto_connect          = optional(number)<br/>    captive_portal        = optional(number)<br/>    disable_auto_fallback = optional(bool)<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    exclude_office_ips = optional(bool)<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      description = optional(string)<br/>      host        = optional(string)<br/>    })))<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    support_url          = optional(string)<br/>    switch_locked        = optional(bool)<br/>    tunnel_protocol      = optional(string)<br/>    uninstall_protection = optional(bool)<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_device_default_profile_certificates"></a> [device\_default\_profile\_certificates](#input\_device\_default\_profile\_certificates) | Device client certificates, one entry per zone, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_default_profile_certificates` under the same names. Removing an entry changes nothing in Cloudflare: apply `enabled = false` first to turn the certificate off, see [Device certificates](#device-certificates). | <pre>map(object({<br/>    enabled = bool<br/>    zone_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_default_profile_local_domain_fallback"></a> [device\_default\_profile\_local\_domain\_fallback](#input\_device\_default\_profile\_local\_domain\_fallback) | Local domain fallback of the default profile, with the attributes of `cloudflare_zero_trust_device_default_profile_local_domain_fallback` under the same names. When `null`, the module leaves it alone. `domains` replaces the whole list, Cloudflare's default domains included. Removing this argument changes nothing in Cloudflare, see [Local domain fallback](#local-domain-fallback). | <pre>object({<br/>    domains = set(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>      dns_server  = optional(list(string))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_device_deployment_groups"></a> [device\_deployment\_groups](#input\_device\_deployment\_groups) | Deployment groups, which set the WARP client version of the devices of their profiles, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_deployment_groups` under the same names. `version` is a full release number, such as `2026.8.2110.0`. Take `policy_ids` from the `device_custom_profile_ids` and `device_default_profile_policy_id` outputs; a profile belongs to one group at most. Once a group holds profiles, it keeps at least one: Cloudflare refuses `policy_ids = []` and ignores a removed `policy_ids`, see [Deployment groups](#deployment-groups). | <pre>map(object({<br/>    name = string<br/>    version_config = list(object({<br/>      target_environment = string<br/>      version            = string<br/>    }))<br/>    policy_ids = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_device_ip_profiles"></a> [device\_ip\_profiles](#input\_device\_ip\_profiles) | Device IP profiles, which choose the subnet of a device, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_ip_profile` under the same names. Take `subnet_id` from the `device_subnet_ids` output. Cloudflare refuses a `precedence` that another IP profile holds (error 2808). Removing `description` keeps it in Cloudflare: write `""` to clear it, see [Device IP profiles and subnets](#device-ip-profiles-and-subnets). | <pre>map(object({<br/>    match       = string<br/>    name        = string<br/>    precedence  = number<br/>    subnet_id   = string<br/>    description = optional(string)<br/>    enabled     = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_device_managed_networks"></a> [device\_managed\_networks](#input\_device\_managed\_networks) | Managed networks, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_managed_networks` under the same names. `config.sha256` defaults to `""`, which Cloudflare returns for a network without fingerprint. Custom profiles match a network by its `name`, which Cloudflare does not check, see [Managed networks](#managed-networks). | <pre>map(object({<br/>    config = object({<br/>      tls_sockaddr = string<br/>      sha256       = optional(string, "")<br/>    })<br/>    name = string<br/>    type = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_posture_integrations"></a> [device\_posture\_integrations](#input\_device\_posture\_integrations) | Device posture integrations with third-party providers, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_posture_integration` under the same names. Cloudflare checks the credentials with the provider when it creates the integration, and creates nothing if they fail (error 2046). Pass `config.client_secret`, `config.client_key` and `config.access_client_secret` from sensitive variables, without marking the map sensitive, see [Device posture integrations](#device-posture-integrations). | <pre>map(object({<br/>    config = object({<br/>      access_client_id     = optional(string)<br/>      access_client_secret = optional(string)<br/>      api_url              = optional(string)<br/>      auth_url             = optional(string)<br/>      client_id            = optional(string)<br/>      client_key           = optional(string)<br/>      client_secret        = optional(string)<br/>      customer_id          = optional(string)<br/>    })<br/>    interval = string<br/>    name     = string<br/>    type     = string<br/>  }))</pre> | `{}` | no |
| <a name="input_device_posture_rules"></a> [device\_posture\_rules](#input\_device\_posture\_rules) | Device posture rules, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_posture_rule` under the same names. `input` takes the fields of the rule `type`; take `input.connection_id` from the `device_posture_integration_ids` output. Leave `input.operating_system` out: Cloudflare drops it, and each plan shows it again. Write `schedule`, `5m` by default, or an imported rule plans a change. Removing `description` keeps it in Cloudflare, see [Device posture rules](#device-posture-rules). | <pre>map(object({<br/>    type        = string<br/>    description = optional(string)<br/>    expiration  = optional(string)<br/>    input = optional(object({<br/>      active_threats     = optional(number)<br/>      auth_state         = optional(list(string))<br/>      certificate_id     = optional(string)<br/>      check_disks        = optional(list(string))<br/>      check_private_key  = optional(bool)<br/>      cn                 = optional(string)<br/>      compliance_status  = optional(string)<br/>      connection_id      = optional(string)<br/>      count_operator     = optional(string)<br/>      domain             = optional(string)<br/>      eid_last_seen      = optional(string)<br/>      enabled            = optional(bool)<br/>      exists             = optional(bool)<br/>      extended_key_usage = optional(list(string))<br/>      id                 = optional(string)<br/>      infected           = optional(bool)<br/>      is_active          = optional(bool)<br/>      issue_count        = optional(string)<br/>      last_seen          = optional(string)<br/>      locations = optional(object({<br/>        paths        = optional(list(string))<br/>        trust_stores = optional(list(string))<br/>      }))<br/>      network_status            = optional(string)<br/>      operating_system          = optional(string)<br/>      operational_state         = optional(string)<br/>      operator                  = optional(string)<br/>      os                        = optional(string)<br/>      os_distro_name            = optional(string)<br/>      os_distro_revision        = optional(string)<br/>      os_version_extra          = optional(string)<br/>      overall                   = optional(string)<br/>      path                      = optional(string)<br/>      require_all               = optional(bool)<br/>      risk_level                = optional(string)<br/>      score                     = optional(number)<br/>      score_operator            = optional(string)<br/>      sensor_config             = optional(string)<br/>      sha256                    = optional(string)<br/>      state                     = optional(string)<br/>      subject_alternative_names = optional(list(string))<br/>      thumbprint                = optional(string)<br/>      total_score               = optional(number)<br/>      update_window_days        = optional(number)<br/>      version                   = optional(string)<br/>      version_operator          = optional(string)<br/>    }))<br/>    match = optional(list(object({<br/>      platform = optional(string)<br/>    })))<br/>    name     = optional(string)<br/>    schedule = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_device_settings"></a> [device\_settings](#input\_device\_settings) | Device settings of the account, with the attributes of `cloudflare_zero_trust_device_settings` under the same names. When `null`, the module leaves them alone. Write every field Cloudflare returns: one left out shows as a change to `null` at each plan, which Cloudflare refuses (error 2024). Removing this argument resets the settings, see [Settings](#settings). | <pre>object({<br/>    disable_for_time                      = optional(number)<br/>    external_emergency_signal_enabled     = optional(bool)<br/>    external_emergency_signal_fingerprint = optional(string)<br/>    external_emergency_signal_interval    = optional(string)<br/>    external_emergency_signal_url         = optional(string)<br/>    gateway_proxy_enabled                 = optional(bool)<br/>    gateway_udp_proxy_enabled             = optional(bool)<br/>    root_certificate_installation_enabled = optional(bool)<br/>    use_zt_virtual_ip                     = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_device_subnets"></a> [device\_subnets](#input\_device\_subnets) | Device subnets, from which a device takes its IP, by a key of your choice, with the attributes of `cloudflare_zero_trust_device_subnet` under the same names. Cloudflare refuses to change `network`: declare the new range under a new key, created before the old one is deleted. `is_default_network = true` takes the default from the former default subnet, outside Terraform; Cloudflare refuses `false` on the default subnet. Write `comment` and `is_default_network` of an imported subnet, see [Device IP profiles and subnets](#device-ip-profiles-and-subnets). | <pre>map(object({<br/>    name               = string<br/>    network            = string<br/>    comment            = optional(string)<br/>    is_default_network = optional(bool)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_device_custom_profile_ids"></a> [device\_custom\_profile\_ids](#output\_device\_custom\_profile\_ids) | IDs of the custom profiles, by key of `device_custom_profiles`: the `policy_id` that `device_custom_profile_local_domain_fallbacks` takes. |
| <a name="output_device_custom_profile_local_domain_fallback_ids"></a> [device\_custom\_profile\_local\_domain\_fallback\_ids](#output\_device\_custom\_profile\_local\_domain\_fallback\_ids) | IDs of the local domain fallbacks of custom profiles, by key of `device_custom_profile_local_domain_fallbacks`. Each one is the ID of its profile. |
| <a name="output_device_default_profile_policy_id"></a> [device\_default\_profile\_policy\_id](#output\_device\_default\_profile\_policy\_id) | Policy ID of the default profile, which `device_deployment_groups` takes in `policy_ids`, when `device_default_profile` is set; `null` otherwise. The ID of the resource is the account ID. |
| <a name="output_device_deployment_group_ids"></a> [device\_deployment\_group\_ids](#output\_device\_deployment\_group\_ids) | IDs of the deployment groups, by key of `device_deployment_groups`. |
| <a name="output_device_ip_profile_ids"></a> [device\_ip\_profile\_ids](#output\_device\_ip\_profile\_ids) | IDs of the device IP profiles, by key of `device_ip_profiles`. |
| <a name="output_device_managed_network_ids"></a> [device\_managed\_network\_ids](#output\_device\_managed\_network\_ids) | IDs of the managed networks, by key of `device_managed_networks`. |
| <a name="output_device_posture_integration_ids"></a> [device\_posture\_integration\_ids](#output\_device\_posture\_integration\_ids) | IDs of the device posture integrations, by key of `device_posture_integrations`: the `input.connection_id` of a rule that checks a third-party provider. |
| <a name="output_device_posture_rule_ids"></a> [device\_posture\_rule\_ids](#output\_device\_posture\_rule\_ids) | IDs of the device posture rules, by key of `device_posture_rules`, for the `device_posture` rules of Access groups and policies and the `device_posture.checks.passed` expressions of Gateway policies. |
| <a name="output_device_subnet_ids"></a> [device\_subnet\_ids](#output\_device\_subnet\_ids) | IDs of the device subnets, by key of `device_subnets`: the `subnet_id` that `device_ip_profiles` takes. |
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
