# cloudflare-dns

Terraform module that manages a Cloudflare DNS zone: the zone itself, its
records, its DNS settings and DNSSEC, on top of the `cloudflare/cloudflare`
provider. Every provider attribute of these resources is available under the
same name, and each one is optional: whatever the caller leaves out keeps
Cloudflare's default.

The module is not released yet. The first release will be tagged
`cloudflare-dns/v1.0.0`, see the [CHANGELOG](CHANGELOG.md).

## Usage

```hcl
module "dns" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-dns?ref=cloudflare-dns/v1.0.0"

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

Each record takes the attributes of
[`cloudflare_dns_record`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record),
and its key in `records` names it in the state. Renaming a key destroys the
record and creates it again: to rename one without touching DNS, add a `moved`
block from `module.dns.cloudflare_dns_record.this["old"]` to
`module.dns.cloudflare_dns_record.this["new"]`.

See the [repository README](../README.md#usage) for the SSH form of the
source and the versioning rules.

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
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the zone. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Domain name of the zone, such as `example.com`. Changing it replaces the zone. | `string` | n/a | yes |
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether the module creates the zone. Set it to `false` when the zone already exists and another configuration manages it: the module then looks the zone up by `name` in the account, manages only its records, DNS settings and DNSSEC, and ignores `type`, `paused` and `vanity_name_servers`. | `bool` | `true` | no |
| <a name="input_paused"></a> [paused](#input\_paused) | Whether the zone only uses Cloudflare DNS, without the security and performance features. When `null`, the provider sets `false`. | `bool` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | DNS records of the zone, by a key of your choice. The key only names the record in the state: keep it stable, since renaming a key replaces the record. Each record takes the attributes of `cloudflare_dns_record` under the same names, and `ttl` defaults to `1` (automatic). Set `content` for A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR and TXT records, `data` for the other types. | <pre>map(object({<br/>    name    = string<br/>    type    = string<br/>    ttl     = optional(number, 1)<br/>    content = optional(string)<br/>    data = optional(object({<br/>      algorithm      = optional(number)<br/>      altitude       = optional(number)<br/>      certificate    = optional(string)<br/>      digest         = optional(string)<br/>      digest_type    = optional(number)<br/>      fingerprint    = optional(string)<br/>      flags          = optional(any)<br/>      key_tag        = optional(number)<br/>      lat_degrees    = optional(number)<br/>      lat_direction  = optional(string)<br/>      lat_minutes    = optional(number)<br/>      lat_seconds    = optional(number)<br/>      long_degrees   = optional(number)<br/>      long_direction = optional(string)<br/>      long_minutes   = optional(number)<br/>      long_seconds   = optional(number)<br/>      matching_type  = optional(number)<br/>      order          = optional(number)<br/>      port           = optional(number)<br/>      precision_horz = optional(number)<br/>      precision_vert = optional(number)<br/>      preference     = optional(number)<br/>      priority       = optional(number)<br/>      protocol       = optional(number)<br/>      public_key     = optional(string)<br/>      regex          = optional(string)<br/>      replacement    = optional(string)<br/>      selector       = optional(number)<br/>      service        = optional(string)<br/>      size           = optional(number)<br/>      tag            = optional(string)<br/>      target         = optional(string)<br/>      type           = optional(number)<br/>      usage          = optional(number)<br/>      value          = optional(string)<br/>      weight         = optional(number)<br/>    }))<br/>    proxied  = optional(bool)<br/>    priority = optional(number)<br/>    comment  = optional(string)<br/>    tags     = optional(set(string))<br/>    settings = optional(object({<br/>      flatten_cname = optional(bool)<br/>      ipv4_only     = optional(bool)<br/>      ipv6_only     = optional(bool)<br/>    }))<br/>    private_routing         = optional(bool)<br/>    include_shadow_metadata = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of the zone: `full`, `partial`, `secondary` or `internal`. When `null`, the provider sets `full`. | `string` | `null` | no |
| <a name="input_vanity_name_servers"></a> [vanity\_name\_servers](#input\_vanity\_name\_servers) | Custom name servers of the zone. Business and Enterprise plans only. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
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
