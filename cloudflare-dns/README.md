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

  # ...
}
```

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

No providers.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
