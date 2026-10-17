# cloudflare-dns

Terraform module that manages a Cloudflare DNS zone: the zone itself, its
records, its DNS settings and DNSSEC, on top of the `cloudflare/cloudflare`
provider. Every provider attribute of these resources is available under the
same name, and each one is optional: whatever the caller leaves out keeps
Cloudflare's default. DNS settings are the exception, see
[DNS settings](#dns-settings).

Releases are tagged `cloudflare-dns/vX.Y.Z` and listed in the
[CHANGELOG](CHANGELOG.md).

## Usage

```hcl
module "dns" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-dns?ref=cloudflare-dns/v1.1.0"

  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  name       = "example.com"

  records = {
    apex = { name = "@", type = "A", content = "192.0.2.10", proxied = true }
    www  = { name = "www", type = "CNAME", content = "example.com", proxied = true }
    mx   = { name = "@", type = "MX", content = "mx1.example.net", priority = 10 }
    caa  = { name = "@", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
  }
}
```

When the zone already exists and another configuration manages it, set
`create_zone = false`: the module looks the zone up by name in the account and
manages only what lives in it.

See the [repository README](../README.md#usage) for the SSH form of the
source and the versioning rules.

### Examples

- [basic](examples/basic): a new zone and a few records, with Cloudflare's
  defaults for the rest.
- [complete](examples/complete): every input of the module.
- [import](examples/import): an existing zone and its records brought under
  Terraform with `import` blocks, record IDs looked up by name, type and
  content.

## Prerequisites

The version constraints are listed under [Requirements](#requirements). The
module is checked with provider 5.27.0, and with Terraform 1.16.5 and 1.3.10:
1.3 is the first version that accepts a default in `optional()`.

The provider authenticates with an API token, read from the
`CLOUDFLARE_API_TOKEN` environment variable. The token needs these
permissions, on all zones of the account, since a zone to be created does not
exist yet when the token is issued:

| Permission | Operations |
|---|---|
| Zone → Zone → Edit | create, update and delete the zone |
| Zone → DNS → Edit | records, DNSSEC and DNS settings of the zone |

## Records

Each entry of `records` takes the attributes of
[`cloudflare_dns_record`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record).
Set `content` for A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR and TXT records, and
`data` for the other types: the plan fails on a record with neither, or with
both. `name` can be `@`, a name relative to the zone
such as `www`, or the fully qualified name: the provider matches it with the
fully qualified name Cloudflare returns, and the plan shows no change.

A record with `settings` is the exception: write its `name` fully qualified,
or set all three fields, `flatten_cname`, `ipv4_only` and `ipv6_only`. With a
relative name and only some of the fields, each plan shows an update of
`modified_on` and nothing else.

Cloudflare rewrites a few values. Write them the way it stores them, or each
plan shows the difference again:

| Record | Write |
|---|---|
| SRV | `priority` at the top level, as well as `data.priority`: Cloudflare returns it there, and without it each plan sets it to `null` |
| NAPTR | `data.replacement` with its final dot |
| SSHFP | `data.fingerprint` in upper case |

MX and URI records take `priority` at the top level only. Cloudflare keeps
the other values as written, such as a TXT `content` with or without quotes,
an SRV `target` without a final dot, the `value` of an HTTPS record or the
`certificate` of a TLSA record.

A proxied record keeps `ttl` at its default, `1` (automatic): Cloudflare sets
the TTL of proxied records, and the plan fails on any other value.

Record `tags` and `settings.flatten_cname = true` need a paid plan, see the
[complete example](examples/complete).

### Rename a key

The key of an entry in `records` only names the record in the state. Renaming
a key destroys the record and creates it again: Terraform deletes the old one
and creates the new one at the same time. To rename a key without touching
DNS, declare the move:

```hcl
moved {
  from = module.dns.cloudflare_dns_record.this["old"]
  to   = module.dns.cloudflare_dns_record.this["new"]
}
```

## Zone

### Delete or replace the zone

Destroying the module deletes the zone, and Cloudflare deletes all its records
with it, including the ones Terraform does not manage. Changing `name` or
`account_id` does the same, since it replaces the zone. Before applying, look
for `module.dns.cloudflare_zone.this[0]` in the plan.

Setting `create_zone = false` on a zone the module created destroys it as
well: the plan shows `module.dns.cloudflare_zone.this[0] will be destroyed`.
To hand the zone over to another configuration, forget it first, see below.

### Stop managing without deleting

To drop the whole module from Terraform and keep the zone and its records,
remove the `module` block and declare its removal, with Terraform 1.7 or
later:

```hcl
removed {
  from = module.dns

  lifecycle {
    destroy = false
  }
}
```

The plan then shows each object as "will no longer be managed by Terraform,
but will not be destroyed". Before Terraform 1.7, run
`terraform state rm module.dns` instead.

A `removed` block cannot target a resource the module still declares, nor one
key of `records`. Use `terraform state rm` for these:

- To keep the records here while another configuration takes the zone over,
  forget the zone, then set `create_zone = false`. The module looks the zone
  up by name, and the plan shows no change:

  ```bash
  terraform state rm 'module.dns.cloudflare_zone.this[0]'
  ```

- To leave one record alone, forget it, then remove its entry from `records`:

  ```bash
  terraform state rm 'module.dns.cloudflare_dns_record.this["www"]'
  ```

## DNS settings

The provider reads every DNS setting back from Cloudflare. A simple setting
left out of `dns_settings`, that is `flatten_all_cnames`, `multi_provider`,
`ns_ttl`, `secondary_overrides` or `zone_mode`, shows as a change to `null` at
each plan: write them all. `soa`, `nameservers` and `internal_dns` can be left
out whole, and the plan shows no change, since the provider keeps what
Cloudflare returns. A `soa` you write needs every field, though: a field left
out shows as a change to `null`.

Only Enterprise zones accept `soa`. On other plans, Cloudflare refuses any
`soa`, even its current values, with `Custom SOA records are not available to
this account or zone` (error 1003), and the apply fails without changing
anything. Leave `soa` out there.

Cloudflare reported these values on 11 October 2026 for a zone on the Free
plan, and this block, applied to that zone, then planned no change:

```hcl
  dns_settings = {
    flatten_all_cnames  = false
    multi_provider      = false
    nameservers         = { type = "cloudflare.standard" }
    ns_ttl              = 86400
    secondary_overrides = false
    zone_mode           = "standard"
  }
```

On an Enterprise zone, add `soa`. The timers below, like `ns_ttl` above, are
the defaults Cloudflare documents for new zones. `soa.mname` stays out:
Cloudflare then picks the primary name server itself and returns `null`.

```hcl
    soa = {
      expire  = 604800
      min_ttl = 1800
      refresh = 10000
      retry   = 2400
      rname   = "dns.cloudflare.com"
      ttl     = 3600
    }
```

The deprecated `foundation_dns` is not part of the module: turn Advanced
Nameservers on with `nameservers = { type = "cloudflare.advanced" }`. The API
still returns `foundation_dns`, so the module ignores its changes, which would
otherwise set it to `null` at each plan. Before Terraform 1.15, this
`ignore_changes` makes `validate` and `plan` warn that `foundation_dns` is
deprecated; the warning is harmless.

The DNS settings cannot be deleted, and the provider cannot import them. The
first apply writes them over the current ones, and removing `dns_settings`
only drops them from the state: the zone keeps the last values applied. To go
back to a default, write it. A plan that creates them warns about "Resource
Destruction Considerations": the provider states the same limit, and the
warning is harmless.

## DNSSEC

### Turn DNSSEC on

1. Set `dnssec = { status = "active" }` and apply. Cloudflare signs the zone
   and computes its DS record.
2. Give the DS record to the registrar, from the `dnssec` output: whole in
   `ds`, or as its fields `key_tag`, `algorithm`, `digest_type` and `digest`.
   Cloudflare adds it on its own for domains on Cloudflare Registrar and for
   `.ch` and `.cz` domains.

Until Cloudflare finds the DS record at the registrar, it reports DNSSEC as
`pending`, and each plan shows `status` going from `"pending"` to `"active"`.
Applying it changes nothing, and the difference goes away once the DS record
is published.

The provider also reads `dnssec_multi_signer`, `dnssec_presigned` and
`dnssec_use_nsec3` back from Cloudflare: if a plan shows one of them going to
`null`, write the value it had.

### Turn DNSSEC off

Removing `dnssec` destroys `cloudflare_zone_dnssec`: the provider disables
DNSSEC, then deletes its records, and Cloudflare stops signing the zone.
Resolvers that validate DNSSEC then fail on the domain (`SERVFAIL`) as long as
they still find its DS record, at the registrar or in their cache. Cloudflare
refuses the deletion while the DS record is at the registrar, but cannot see
the caches. Go through the registrar first:

1. Set `status = "disabled"` and apply. Cloudflare keeps signing the zone, so
   nothing breaks, and publishes CDS and CDNSKEY records that ask the
   registrar to remove the DS record
   ([RFC 8078](https://www.rfc-editor.org/rfc/rfc8078.html#section-4)). Until
   the DS record is gone, Cloudflare reports `pending-disabled`, and each plan
   shows `status` going from `"pending-disabled"` to `"disabled"`.
2. Note the TTL of the DS record, then remove it at the registrar. Cloudflare
   Registrar removes it on its own after step 1.
3. Wait until the parent zone no longer serves the DS record, then at least
   1.5 times its TTL, as Cloudflare advises, for resolvers to drop it from
   their caches:

   ```bash
   # Name servers of the parent zone, here .com
   dig +short NS com.
   # No answer once the DS record is removed
   dig +norecurse +noall +answer DS example.com @a.gtld-servers.net
   ```

4. Remove `dnssec` and apply. Keeping `dnssec = { status = "disabled" }`
   instead leaves the zone signed with its DNSKEY records published: resolvers
   ignore them without a DS record, though some audit tools flag them.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.27 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.27 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_dns_record.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone) | resource |
| [cloudflare_zone_dns_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_dns_settings) | resource |
| [cloudflare_zone_dnssec.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_dnssec) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the zone. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Domain name of the zone, such as `example.com`. Changing it replaces the zone. | `string` | n/a | yes |
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether the module creates the zone. Set it to `false` when the zone already exists and another configuration manages it: the module then looks the zone up by `name` in the account, manages only its records, DNS settings and DNSSEC, and ignores `type`, `paused` and `vanity_name_servers`. | `bool` | `true` | no |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | DNS settings of the zone, with the attributes of `cloudflare_zone_dns_settings` under the same names, except the deprecated `foundation_dns`. When `null`, the module leaves them alone. Write `flatten_all_cnames`, `multi_provider`, `ns_ttl`, `secondary_overrides` and `zone_mode`: one left out shows as a change to `null` at each plan. `soa` is only accepted on Enterprise zones: elsewhere the API refuses it, even unchanged (error 1003). Leave it out, and the plan shows no change: the provider reads it back from Cloudflare. Removing this argument resets nothing, see [DNS settings](#dns-settings). | <pre>object({<br/>    flatten_all_cnames = optional(bool)<br/>    internal_dns = optional(object({<br/>      reference_zone_id = optional(string)<br/>    }))<br/>    multi_provider = optional(bool)<br/>    nameservers = optional(object({<br/>      type              = string<br/>      nameserver_set_id = optional(string)<br/>      ns_set            = optional(number)<br/>    }))<br/>    ns_ttl              = optional(number)<br/>    secondary_overrides = optional(bool)<br/>    soa = optional(object({<br/>      expire  = optional(number)<br/>      min_ttl = optional(number)<br/>      mname   = optional(string)<br/>      refresh = optional(number)<br/>      retry   = optional(number)<br/>      rname   = optional(string)<br/>      ttl     = optional(number)<br/>    }))<br/>    zone_mode = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_dnssec"></a> [dnssec](#input\_dnssec) | DNSSEC of the zone, with the attributes of `cloudflare_zone_dnssec` under the same names. When `null`, the module leaves DNSSEC alone. Set `status = "active"` to sign the zone, then give the `dnssec` output to the registrar. Removing this argument deletes the DNSSEC keys: remove the DS record at the registrar first, see [Turn DNSSEC off](#turn-dnssec-off). | <pre>object({<br/>    status              = optional(string)<br/>    dnssec_multi_signer = optional(bool)<br/>    dnssec_presigned    = optional(bool)<br/>    dnssec_use_nsec3    = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_paused"></a> [paused](#input\_paused) | Whether the zone only uses Cloudflare DNS, without the security and performance features. When `null`, the provider sets `false`. | `bool` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | DNS records of the zone, by a key of your choice. The key only names the record in the state: keep it stable, since renaming a key replaces the record. Each record takes the attributes of `cloudflare_dns_record` under the same names, and `ttl` defaults to `1` (automatic). Set `content` for A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR and TXT records, `data` for the other types. | <pre>map(object({<br/>    name    = string<br/>    type    = string<br/>    ttl     = optional(number, 1)<br/>    content = optional(string)<br/>    data = optional(object({<br/>      algorithm      = optional(number)<br/>      altitude       = optional(number)<br/>      certificate    = optional(string)<br/>      digest         = optional(string)<br/>      digest_type    = optional(number)<br/>      fingerprint    = optional(string)<br/>      flags          = optional(any)<br/>      key_tag        = optional(number)<br/>      lat_degrees    = optional(number)<br/>      lat_direction  = optional(string)<br/>      lat_minutes    = optional(number)<br/>      lat_seconds    = optional(number)<br/>      long_degrees   = optional(number)<br/>      long_direction = optional(string)<br/>      long_minutes   = optional(number)<br/>      long_seconds   = optional(number)<br/>      matching_type  = optional(number)<br/>      order          = optional(number)<br/>      port           = optional(number)<br/>      precision_horz = optional(number)<br/>      precision_vert = optional(number)<br/>      preference     = optional(number)<br/>      priority       = optional(number)<br/>      protocol       = optional(number)<br/>      public_key     = optional(string)<br/>      regex          = optional(string)<br/>      replacement    = optional(string)<br/>      selector       = optional(number)<br/>      service        = optional(string)<br/>      size           = optional(number)<br/>      tag            = optional(string)<br/>      target         = optional(string)<br/>      type           = optional(number)<br/>      usage          = optional(number)<br/>      value          = optional(string)<br/>      weight         = optional(number)<br/>    }))<br/>    proxied  = optional(bool)<br/>    priority = optional(number)<br/>    comment  = optional(string)<br/>    tags     = optional(set(string))<br/>    settings = optional(object({<br/>      flatten_cname = optional(bool)<br/>      ipv4_only     = optional(bool)<br/>      ipv6_only     = optional(bool)<br/>    }))<br/>    private_routing         = optional(bool)<br/>    include_shadow_metadata = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of the zone: `full`, `partial`, `secondary` or `internal`. When `null`, the provider sets `full`. | `string` | `null` | no |
| <a name="input_vanity_name_servers"></a> [vanity\_name\_servers](#input\_vanity\_name\_servers) | Custom name servers of the zone. Business and Enterprise plans only. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dnssec"></a> [dnssec](#output\_dnssec) | DNSSEC of the zone, or `null` when the module does not manage it. Give the registrar the DS record, whole in `ds` or as its fields `key_tag`, `algorithm`, `digest_type` and `digest`. Some registrars ask for the DNSKEY record instead: `flags`, `algorithm` and `public_key`. |
| <a name="output_name"></a> [name](#output\_name) | Domain name of the zone. |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers Cloudflare assigned to the zone, to set at the registrar. |
| <a name="output_record_ids"></a> [record\_ids](#output\_record\_ids) | IDs of the DNS records, by key of `records`. |
| <a name="output_status"></a> [status](#output\_status) | Status of the zone: `initializing`, `pending`, `active` or `moved`. A new full zone stays `pending` until the registrar delegates the domain to `name_servers`. |
| <a name="output_verification_key"></a> [verification\_key](#output\_verification\_key) | Verification key for a partial zone setup. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ID of the zone. |
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
