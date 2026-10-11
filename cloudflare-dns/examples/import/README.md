# Import example

Brings an existing zone and its records under Terraform without touching DNS,
with `import` blocks. The module cannot hold them: they live in the
configuration that calls it, as here. Nothing needs copying from the
dashboard: the example looks the zone up by name, and each record by its
name, type and content in the `cloudflare_dns_records` data source.

This example needs Terraform 1.7 or later, for `for_each` in `import` blocks.

## Steps

1. Write the zone's records in `local.records`, under keys of your choice, as
   they are in Cloudflare. For a large zone,
   [`cf-terraforming`](https://github.com/cloudflare/cf-terraforming) writes
   them out, and each of its `cloudflare_dns_record` blocks becomes an entry,
   without `zone_id`:

   ```bash
   cf-terraforming generate --resource-type cloudflare_dns_record --zone <zone_id>
   ```

2. Plan, and read it:

   ```bash
   export CLOUDFLARE_API_TOKEN=...
   terraform init
   terraform plan -var account_id=<account_id>
   ```

   Expect every record to import, the zone with them, and nothing to add,
   change or destroy:

   ```text
   Plan: 8 to import, 0 to add, 0 to change, 0 to destroy.
   ```

   A record to add is an entry that matched no existing record, listed in the
   `unmatched_records` output. Unless you mean to add it, fix its name, type,
   `content` or `data` to what Cloudflare holds: the apply would otherwise
   create a second record next to the one in place. A change is an attribute
   that differs, such as `ttl` or `proxied`: write the current value, or keep
   the change if you want it.

   When the map holds a NAPTR record, the plan also changes the `flags` of
   each CAA record from `0` to `"0"`: an attribute has one type across a map,
   and NAPTR flags are text. Cloudflare stores the same number, and the next
   plan is empty.

3. Apply. The `import` blocks and the data sources can go afterwards: an
   `import` block whose resource is already in the state does nothing.

## Matching rule

An entry stands for the existing record with the same type and name, and:

- for a record with `content`, the same `content`;
- for a record with `data`, the same value in each field of `data` the entry
  sets. Two CAA records at the apex differ by `tag` or `value`, two SRV
  records by `port` or `target`.

Write the values as the API returns them, which is how `cf-terraforming`
writes them: a TXT `content` with its quotes, a NAPTR `replacement` with its
final dot, an SSHFP `fingerprint` in upper case. Write an SRV `priority` at
the top level as well as in `data`: the record still imports without it, but
each plan then sets it to `null`, see [Records](../../README.md#records). `ttl`, `proxied` and the other attributes do not count, so a
difference there shows as a change, not as a record to add.

The data source reads the records one type at a time: read together, a record
with `data.flags` (CAA, NAPTR) and a record of another type make Terraform
crash with `inconsistent list element types`
([provider issue #7004](https://github.com/cloudflare/terraform-provider-cloudflare/issues/7004)).

## DNSSEC and DNS settings

If the zone has DNSSEC on, set `dnssec` in the module and import it with the
zone ID:

```hcl
import {
  to = module.dns.cloudflare_zone_dnssec.this[0]
  id = data.cloudflare_zone.existing.id
}
```

The provider cannot import DNS settings. Leave `dns_settings` out, or write
the current values: the first apply writes them over the ones in place, see
[DNS settings](../../README.md#dns-settings).
