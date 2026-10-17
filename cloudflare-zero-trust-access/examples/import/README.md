# Import example

Brings an existing Access setup under Terraform without changing it, with
`import` blocks: the organization, identity providers, groups, reusable
policies and applications. The module cannot hold them: they live in the
configuration that calls it, as here. Nothing needs copying from the
dashboard: the example looks each object up by name in the provider's data
sources.

This example needs Terraform 1.7 or later, for `for_each` in `import` blocks.

## Steps

1. Write the objects in `local.identity_providers`, `local.groups`,
   `local.policies` and `local.applications`, under keys of your choice, as
   they are in Cloudflare, and the settings of the organization in
   `organization`. Objects refer to each other through the module's outputs,
   as in the rest of the module.

2. Plan, and read it:

   ```bash
   export CLOUDFLARE_API_TOKEN=...
   terraform init
   terraform plan -var account_id=<account_id>
   ```

   Expect every object to import, and nothing to add or destroy:

   ```text
   Plan: 5 to import, 0 to add, 1 to change, 0 to destroy.
   ```

   The change is the organization: an organization left at its defaults
   returns a `service_token_inactivity` that the provider refuses as input,
   and the plan sets it to `null`. Applying leaves the organization as it
   was, see [Adopt the organization](../../README.md#adopt-the-organization).

   An object to add is an entry that matched no existing object, listed in
   the `unmatched` output. Unless you mean to add it, fix its name, or its
   `type`: the apply would otherwise create a second object next to the one
   in place. A change is an attribute that differs: write the current value,
   or keep the change if you want it.

3. Apply. The `import` blocks and the data sources can go afterwards: an
   `import` block whose resource is already in the state does nothing.

## Matching rule

An entry stands for the existing object with the same name, and the same
`type` for identity providers and applications. When two objects match an
entry, `one()` fails the plan: rename one in Cloudflare, or import the entry
by its ID.

## Values to write

An import plan shows a change for some values that Cloudflare returns, and
that a configuration written by hand leaves out:

- a one-time PIN set up from the dashboard can have an empty name: write
  `name = ""`;
- an Entra ID provider returns `conditional_access_enabled = false`;
- a policy created in the dashboard returns `session_duration = "24h"`;
- an application returns `false` for `auto_redirect_to_identity`, and for
  `enable_binding_cookie` and `options_preflight_bypass` when its type takes
  them.

The example writes those it uses. Other changes remain whatever the
configuration, and one apply clears them:

- the `service_token_inactivity` of the organization, above;
- the `client_secret` of an identity provider, which Cloudflare never
  returns;
- the policies written inside an `infrastructure` application, and two
  booleans of an `mcp` application.

See [Adopt an existing setup](../../README.md#adopt-an-existing-setup).

## Other objects

The module README gives the import ID of every other input, and what the plan
shows after the import, in
[Adopt an existing setup](../../README.md#adopt-an-existing-setup). Read it
before importing service tokens, whose expiration restarts at the first
apply, and mTLS certificates, which the plan of an `import` block replaces:
see [Import an mTLS certificate](../../README.md#import-an-mtls-certificate).
