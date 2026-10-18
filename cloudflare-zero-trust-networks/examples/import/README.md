# Import example

Brings existing tunnels and networks under Terraform without changing them,
with `import` blocks: tunnels and their remote configuration, virtual
networks, the `default` one included, CIDR and hostname routes, and WARP
Connectors. The module cannot hold the `import` blocks: they live in the
configuration that calls it, as here. The example looks each object up in the
provider's data sources, by name, network or hostname, except the WARP
Connectors, whose IDs you give.

This example needs Terraform 1.7 or later, for `for_each` in `import` blocks.

## Steps

1. Write the objects in `local.tunnels`, `local.tunnel_configs`,
   `local.virtual_networks`, `local.routes`, `local.hostname_routes` and
   `local.warp_connectors`, under keys of your choice, as they are in
   Cloudflare. A configuration takes the key of its tunnel, and a route the
   keys of its tunnel or WARP Connector and of its virtual network.

2. Give the IDs of the WARP Connectors, from **Networking** > **Mesh** in the
   dashboard, in `warp_connector_ids`. Provider 5.28.0 cannot look them up:
   its data sources of WARP Connectors fail with `RFC3339 string value is
   null`, and return no connector that never connected when the filters
   avoid the error (provider issue
   [#7417](https://github.com/cloudflare/terraform-provider-cloudflare/issues/7417)).

3. Plan, and read it:

   ```bash
   export CLOUDFLARE_API_TOKEN=...
   terraform init
   terraform plan -var account_id=<account_id> -var 'warp_connector_ids={datacenter="<id>"}'
   ```

   Expect every object to import, and nothing to add, change or destroy:

   ```text
   Plan: 8 to import, 0 to add, 0 to change, 0 to destroy.
   ```

   An object to add is an entry that matched no existing object, listed in
   the `unmatched` output. Unless you mean to add it, fix its name, network
   or hostname: the apply would otherwise create a second tunnel next to the
   one in place, or fail on a route that already exists. A change is an
   attribute that differs: write the current value, see below.

4. Apply. The `import` blocks and the data sources can go afterwards: an
   `import` block whose resource is already in the state does nothing.

## Matching rule

An entry stands for the existing object with the same name, for tunnels and
virtual networks; the same network in the same virtual network, for CIDR
routes; the same hostname, for hostname routes. The data sources leave out
deleted objects, which Cloudflare keeps under their names. When two objects
match an entry, `one()` fails the plan: rename one in Cloudflare, or import
the entry by its ID.

## Values to write

An import plan shows a change for some values that Cloudflare returns, and
that a configuration written by hand leaves out:

- a tunnel configured from Cloudflare, as every tunnel created in the
  dashboard is, returns `config_src = "cloudflare"`. Left out, the plan
  updates it to `local`;
- the `default` virtual network returns `is_default_network = true` and the
  comment Cloudflare gave it. Left out, the plan turns it into a network
  that is not the default one, and empties the comment;
- a hostname route without a comment returns `comment = ""`. Left out, the
  plan sends `null`, which Cloudflare refuses with a `500 Internal Server
  Error`;
- an HA WARP Connector returns `ha = true`. Left out, the plan sets it to
  `false`, which Cloudflare refuses with `Tunnel not found`.

Leave out `tunnel_secret`, which Cloudflare never returns: written, it shows
as an update, and applying it changes the token of the tunnel. A CIDR route
without a comment returns `comment = ""` too, which the provider also takes
when it is left out.

These were checked on 17 October 2026, with provider 5.28.0: 14 objects
created by the module, then imported by this example into an empty state,
planned no change.

## Other objects

The HA configuration of a WARP Connector and the connectivity settings of the
account import by hand, see
[Adopt an existing setup](../../README.md#adopt-an-existing-setup) for their
import IDs and what the plan shows after the import.
