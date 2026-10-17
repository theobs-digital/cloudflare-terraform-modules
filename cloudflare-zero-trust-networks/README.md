# cloudflare-zero-trust-networks

Terraform module that manages the private networks of Cloudflare Zero Trust:
Cloudflare Tunnels and their configuration, WARP Connectors, virtual
networks, CIDR and hostname routes, and the connectivity settings of the
account, on top of the `cloudflare/cloudflare` provider. Every provider
attribute of these resources is available under the same name, and each one
is optional unless the provider requires it: whatever the caller leaves out
keeps Cloudflare's default.

The module hands out the IDs of its virtual networks, which Access
applications and device profiles take, and the tokens that run `cloudflared`
and WARP Connector.

The module is not released yet. The first release will be tagged
`cloudflare-zero-trust-networks/v1.0.0`, see the [CHANGELOG](CHANGELOG.md).

## Usage

```hcl
module "networks" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-zero-trust-networks?ref=cloudflare-zero-trust-networks/v1.0.0"

  # ...
}
```

See the [repository README](../README.md#usage) for the SSH form of the
source and the versioning rules.

## Prerequisites

The version constraints are listed under [Requirements](#requirements).

The provider authenticates with an API token, read from the
`CLOUDFLARE_API_TOKEN` environment variable.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.28 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the Cloudflare account that owns the tunnels, WARP Connectors and networks. Changing it replaces every resource of the module. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Development

See the [repository README](../README.md#development) for the tools and the
checks.
