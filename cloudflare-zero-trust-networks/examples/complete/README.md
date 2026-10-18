# Complete example

Sets every input of the module, for two sites and an office:

- `paris`, a tunnel configured from Cloudflare: a public application with an
  API that cloudflared only forwards with a valid Access token, SSH, a
  private hostname, and IPv4 and IPv6 routes in the `prod` virtual network;
- `lyon`, a tunnel configured by the cloudflared file on its host, with a
  secret you give, that serves the same CIDR as Paris in the `staging`
  virtual network;
- `office`, a WARP Connector (a Mesh node in the dashboard) that routes the
  office LAN in the default virtual network, and `datacenter`, a WARP
  Connector run by two hosts that share a virtual IP;
- the connectivity settings of the account, with the ICMP proxy on.

Objects refer to each other through the module's outputs, see
[How it works](../../README.md#how-it-works). Everything here is accepted on
the Free plan, with a Zero Trust organization.

> [!IMPORTANT]
> `connectivity_settings` writes the settings of the whole account at the
> first apply. Import them first, and write the values Cloudflare returns,
> see [Connectivity settings](../../README.md#connectivity-settings), or
> remove `connectivity_settings` to leave them alone.

```bash
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_lyon_tunnel_secret="$(openssl rand -base64 32)"
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353 -var api_aud=<aud>
```

`api_aud` is the AUD of the Access application that protects
`app.example.com/api/`, such as the `access_application_auds` output of the
`cloudflare-zero-trust-access` module.

## After the apply

- Run `cloudflared` with each token of the `tunnel_tokens` output, see
  [Run the tunnel](../../README.md#run-the-tunnel). In Lyon, give it the
  configuration file with `--config`.
- Add proxied CNAME records `app` and `ssh` to
  `<paris id>.cfargotunnel.com`, from the `tunnel_ids` output, see
  [Publish a hostname](../../README.md#publish-a-hostname).
- Register the office host and the two datacenter hosts with the tokens of
  the `warp_connector_tokens` output, see
  [Run a WARP Connector](../../README.md#run-a-warp-connector).
- Give the `virtual_network_ids` output to the private destinations of
  Access applications and to device profiles.
