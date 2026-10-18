# Basic example

Declares two device posture rules, macOS 15 or later and disk encryption,
that Access and Gateway policies can require, and a device profile for the
Engineering group, which locks the client switch and connects over MASQUE.
The other devices keep the default profile, which the module leaves alone.

```bash
export CLOUDFLARE_API_TOKEN=...
terraform init
terraform apply -var account_id=023e105f4ecef8ad9ca31a8372d0c353
```

The token needs Account → Zero Trust → Edit, and the account a Zero Trust
organization.

## After the apply

- Require the rules in Access or Gateway policies, with the IDs of the
  `device_posture_rule_ids` output, see
  [Require a posture check](../../README.md#require-a-posture-check).
- `identity.groups.name` matches the groups that the identity provider of the
  organization sends: the devices of users in no group named `Engineering`
  keep the default profile.
