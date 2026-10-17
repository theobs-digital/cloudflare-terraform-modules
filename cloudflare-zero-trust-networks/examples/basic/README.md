# Basic example

Connects an office network to Cloudflare through one tunnel, configured from
Cloudflare: `wiki.example.com` serves the wiki that runs next to
`cloudflared`, and devices with the Cloudflare One Client (WARP) reach the
office LAN, `192.168.1.0/24`, through the default virtual network. The
configuration and the route refer to the tunnel through the module's outputs.

```bash
export CLOUDFLARE_API_TOKEN=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353
```

## After the apply

- On a host of the office network, run `cloudflared` with the token of the
  `tunnel_token` output, see [Run the tunnel](../../README.md#run-the-tunnel):

  ```bash
  export TUNNEL_TOKEN="$(terraform output -raw tunnel_token)"
  cloudflared tunnel --no-autoupdate run
  ```

- Add a proxied CNAME record `wiki` to `<tunnel_id>.cfargotunnel.com`, with
  the `tunnel_id` output: the ingress rule creates no DNS record, see
  [Publish a hostname](../../README.md#publish-a-hostname).
- For devices to reach the LAN, enroll them in the Zero Trust organization,
  and send `192.168.1.0/24` through the client in the Split Tunnels of their
  device profile: by default, the client leaves private ranges out. This
  module manages neither, see Cloudflare's
  [Connect an IP/CIDR](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/private-net/cloudflared/connect-cidr/).
