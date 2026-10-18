# Import example

Brings an existing device setup under Terraform without changing it, with
`import` blocks: the default profile and its local domain fallback, custom
profiles and their fallbacks, managed networks, posture rules, subnets, IP
profiles and deployment groups. The module cannot hold the `import` blocks:
they live in the configuration that calls it, as here. The example looks each
object up in the provider's data sources, by name, except subnets and
deployment groups, whose IDs you give.

This example needs Terraform 1.7 or later, for `for_each` in `import` blocks.

## Steps

1. Write the objects in the `locals` of `main.tf`, under keys of your choice,
   as they are in Cloudflare. A local domain fallback takes the key of its
   profile, an IP profile the key of its subnet in `subnet`, and a deployment
   group the keys of its profiles in `profiles`, `default` for the default
   profile.

2. Give the IDs of the subnets and deployment groups, from the API:

   ```bash
   curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/zerotrust/subnets" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
   curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/devices/deployment-groups" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
   ```

   The provider has no data source that lists subnets, and the one that lists
   deployment groups reads the same page again and again in provider 5.28.0.

3. Plan, and read it:

   ```bash
   export CLOUDFLARE_API_TOKEN=...
   terraform init
   terraform plan -var account_id=<account_id> \
     -var 'subnet_ids={engineering="<id>"}' \
     -var 'deployment_group_ids={ring0="<id>"}'
   ```

   Expect every object to import, and nothing to add, change or destroy:

   ```text
   Plan: 9 to import, 0 to add, 0 to change, 0 to destroy.
   ```

   An object to add is an entry that matched no existing object, listed in
   the `unmatched` output. Unless you mean to add it, fix its name: the apply
   would otherwise create a second object next to the one in place, or fail
   on a `precedence` it holds. A change is an attribute that differs: write
   the current value, see below.

4. Apply. The `import` blocks and the data sources can go afterwards: an
   `import` block whose resource is already in the state does nothing.

## Matching rule

An entry stands for the existing object with the same name. When two objects
of a kind share the name, `one()` fails the plan: rename one in Cloudflare,
or import the entry by its ID.

## Values to write

An import plan shows a change for some values that Cloudflare holds, and
that a configuration written by hand leaves out:

- the attributes of a profile that have a provider default, such as
  `tunnel_protocol` or `allowed_to_leave`: left out, the plan writes the
  default over Cloudflare's value. `exclude`, `include`, `service_mode_v2`
  and `dns_search_suffixes` of the default profile: left out, the plan shows
  an empty update. The `locals` hold the default profile of an organization
  on the Free plan, see [Default profile](../../README.md#default-profile);
- `schedule` of a posture rule, `5m` unless set: left out, the plan sends
  `null`. The first plan after importing a `serial_number` or `application`
  rule shows a written `schedule = "5m"` as an update, which changes nothing
  in Cloudflare. `check_disks = []` of a `disk_encryption` rule without
  disks;
- `comment` and `is_default_network` of a subnet: left out, they take `""`
  and `false`.

These were checked on 18 October 2026, with provider 5.28.0: 18 objects
created by the module, the default profile and its fallback, imported by
this example into an empty state, planned no change but the `schedule` of a
`serial_number` and an `application` rule.

## Other objects

The device settings and the device certificates cannot be imported, and the
credentials of a posture integration are never read back, see
[Adopt an existing setup](../../README.md#adopt-an-existing-setup).
