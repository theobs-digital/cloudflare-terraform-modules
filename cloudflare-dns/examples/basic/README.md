# Basic example

Creates the zone `example.com` and four records. Cloudflare's defaults apply
to everything else: the zone is a full setup, DNSSEC and the DNS settings are
left alone.

```bash
export CLOUDFLARE_API_TOKEN=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353
```

The zone stays `pending` until the registrar delegates the domain to the name
servers in the `name_servers` output.
