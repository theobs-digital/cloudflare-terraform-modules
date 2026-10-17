# Complete example

Sets every input of the module: the organization, with its login page and
custom pages; a one-time PIN and Microsoft Entra ID with SCIM; groups and
reusable policies, one of them with approval; applications of six types,
`self_hosted`, `ssh`, `saas`, `infrastructure`, `mcp_portal` and `mcp`; a
service token; an mTLS certificate authority and the hostname settings; the
SSH certificate authority of the `ssh` application; a tag; the rotation of the
signing keys; two infrastructure targets; an MCP server and its portal.
Objects refer to each other through the module's outputs, see
[How it works](../../README.md#how-it-works).

Some of these need a paid plan, and the apply fails without one:

| Input | Plans |
|---|---|
| `access_mtls_certificates` | Pay-as-you-go and Enterprise |
| `access_custom_pages`, and the `custom_pages` of `organization` and of the `wiki` application that refer to them | Pay-as-you-go and Enterprise |

Remove them to try the example on a Free plan. While a custom page fails,
Terraform creates none of the applications, see
[Tags and custom pages](../../README.md#tags-and-custom-pages).

## Apply

The Zero Trust organization must exist: create it in the Zero Trust
dashboard. Before the first apply, import it, or the apply resets the
settings that `organization` leaves out. Add this block, then copy into
`organization` each value that the plan sets to `null` and that you want to
keep, see [Organization](../../README.md#organization):

```hcl
import {
  to = module.access.cloudflare_zero_trust_organization.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

`access_mtls_hostname_settings` and `access_key_configuration` replace the
settings of the account as well, without an import: see
[Hostname settings](../../README.md#hostname-settings) and
[Signing keys](../../README.md#signing-keys).

```bash
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_entra_client_secret=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353 -var client_ca_certificate="$(cat ca.pem)"
```

## After the apply

- Give Microsoft Entra ID the SCIM base URL and secret of the `entra_scim`
  output, the CRM the client ID and secret of `crm_oidc`, and the CI the
  credentials of `ci_client_id` and `ci_client_secret`.
- Trust the `ssh_ca_public_key` output on the SSH servers behind
  `ssh.example.com`, in `TrustedUserCAKeys`.
- Each origin can check the Access token against its AUD, in the
  `application_auds` output.
- Point `mcp.example.com` to the portal with a proxied CNAME record to
  `gateway.agents.cloudflare.com`: the API does not create it, see
  [MCP servers and portals](../../README.md#mcp-servers-and-portals).
- Route `10.0.0.11` and `10.0.0.12` through a Cloudflare Tunnel, in the
  default virtual network, for Access to reach the databases.
