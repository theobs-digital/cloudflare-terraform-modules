# Complete example

Sets every input of the module, for an organization with an office and an
Engineering group:

- the device settings of the account, and a default profile that sends
  private ranges through Cloudflare, to the networks behind tunnels, with a
  local domain fallback for `corp.example.com`;
- the client certificate on a zone, for mTLS;
- an `Office` managed network, and the profile of the devices on it, which
  reach the office LAN directly;
- an `Engineering` profile, with its own local domain fallback;
- posture rules: OS version, firewall, disk encryption, a serial number in a
  Gateway list, a client certificate issued by a company CA, and the score of
  a posture service of your own, through a `custom_s2s` integration;
- a subnet and an IP profile, which give Engineering devices their IPs from
  `10.80.0.0/16`;
- two deployment groups: Engineering takes a client release first, the
  default and office profiles follow.

Objects refer to each other through the module's outputs, see
[How it works](../../README.md#how-it-works).

> [!IMPORTANT]
> `device_settings` and `device_default_profile` act on every device of the
> account. Read the settings and import the default profile first, and write
> the values Cloudflare returns, see [Settings](../../README.md#settings) and
> [Default profile](../../README.md#default-profile), or remove them to leave
> them alone. Removing `device_settings` afterwards resets the settings.

```bash
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_posture_service_client_secret=...
terraform init
terraform apply \
  -var account_id=023e105f4ecef8ad9ca31a8372d0c353 \
  -var zone_id=<zone_id> \
  -var serial_number_list_id=<list_id> \
  -var client_ca_certificate_id=<certificate_id> \
  -var posture_service_client_id=<client_id>.access
```

- `serial_number_list_id` is a Gateway list of type `SERIAL`, such as the
  `list_ids` output of the `cloudflare-zero-trust-gateway` module.
- `client_ca_certificate_id` is a `cloudflare_mtls_certificate` that holds the
  CA of client certificates.
- `posture_service_client_id` and its secret are an Access service token,
  such as the `access_service_token_client_ids` output of the
  `cloudflare-zero-trust-access` module. Cloudflare calls
  `https://posture.example.com/devices` with it to create the integration:
  put the URL of a service that answers, see
  [Posture integrations](../../README.md#posture-integrations).

The token needs the three permissions of the
[Quick start](../../README.md#quick-start).

## After the apply

- Require the posture rules in Access or Gateway policies, with the IDs of
  the `device_posture_rule_ids` output, see
  [Require a posture check](../../README.md#require-a-posture-check).
- To give devices their IPs from the subnet, turn on *Assign a unique IP
  address to each device* in the device settings, see
  [Subnets and IP profiles](../../README.md#subnets-and-ip-profiles).
