# Basic example

Puts `wiki.example.com` behind Access, for the users of `example.com`: a
reusable policy, and an application that refers to it through the module's
outputs. Users sign in with the identity providers of the organization. The
module leaves everything else alone: the organization, its identity providers
and its signing keys.

The Zero Trust organization must exist: create it in the Zero Trust
dashboard, see [Organization](../../README.md#organization). Access only sees
the requests that reach Cloudflare: `wiki.example.com` must be a proxied
record in a zone of the account, or the public hostname of a tunnel.

```bash
export CLOUDFLARE_API_TOKEN=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353
```

The origin can check the Access token of each request against the `wiki_aud`
output.
