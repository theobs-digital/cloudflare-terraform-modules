# Complete example

Sets every input of the module: the zone with its type, pause and custom name
servers, records with `content` and with `data` and their optional
attributes, the DNS settings and DNSSEC.

Some of these need a paid plan, and the apply fails without one:

| Input | Plans |
|---|---|
| `vanity_name_servers` | Business and Enterprise |
| `tags` of a record | Pro, Business and Enterprise |
| `settings.flatten_cname` of a record | Pro, Business and Enterprise |

Remove them to try the example on a Free plan.

```bash
export CLOUDFLARE_API_TOKEN=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353
```

The zone stays `pending` until the registrar delegates the domain to the name
servers in the `name_servers` output, and DNSSEC stays `pending` until the
registrar publishes the DS record from the `dnssec` output. See
[DNSSEC](../../README.md#dnssec).
