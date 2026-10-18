# cloudflare-terraform-modules

Terraform modules for [Cloudflare](https://www.cloudflare.com/), on top of the
[`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
provider. The modules stay thin: each input maps to a provider resource and
keeps its attribute names, so whoever knows the provider knows the module.

## Modules

| Module | Manages | Terraform Registry | Latest release |
|---|---|---|---|
| [`cloudflare-dns`](cloudflare-dns) | A DNS zone: the zone, its records, its DNS settings and DNSSEC | [`theobs-digital/dns/cloudflare`](https://registry.terraform.io/modules/theobs-digital/dns/cloudflare) | [`cloudflare-dns/v1.2.1`](cloudflare-dns/CHANGELOG.md) |
| [`cloudflare-zero-trust-access`](cloudflare-zero-trust-access) | Cloudflare Access: the Zero Trust organization, identity providers, groups and reusable policies, applications, service tokens, mTLS and short-lived certificates, tags, custom pages, key rotation, infrastructure targets, MCP servers and portals | not published | [`cloudflare-zero-trust-access/v1.0.0`](cloudflare-zero-trust-access/CHANGELOG.md) |
| [`cloudflare-zero-trust-networks`](cloudflare-zero-trust-networks) | Zero Trust private networks: Cloudflare Tunnels and their configuration, WARP Connectors (Mesh nodes) and their HA configuration, virtual networks, CIDR and hostname routes, connectivity settings | not published | [`cloudflare-zero-trust-networks/v1.0.0`](cloudflare-zero-trust-networks/CHANGELOG.md) |

## Usage

Take a module from the Terraform Registry, with a version constraint:

```hcl
module "dns" {
  source  = "theobs-digital/dns/cloudflare"
  version = "~> 1.2"

  # ...
}
```

The Registry needs one repository per module, with the module at its root.
Each release is therefore also published to the module's own repository,
such as [`terraform-cloudflare-dns`](https://github.com/theobs-digital/terraform-cloudflare-dns),
tagged `vX.Y.Z`. That repository is a copy: issues and pull requests come here.

Each module lives in its own folder and is released on its own, under a tag
prefixed by the folder name, such as `cloudflare-dns/v1.0.0`. To take a
module from this repository instead, reference it by Git, with the folder
after `//` and the tag in `ref`:

```hcl
module "dns" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-dns?ref=cloudflare-dns/v1.2.1"

  # ...
}
```

Terraform clones the repository over HTTPS, which needs no credentials. To
clone over SSH instead, write the source as
`git::ssh://git@github.com/theobs-digital/cloudflare-terraform-modules.git//cloudflare-dns?ref=cloudflare-dns/v1.2.1`.

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
module by module, and each module records its changes in its own
`CHANGELOG.md`. Always set `ref` to a tag: without it, Terraform takes the
latest commit of the default branch.

## Development

### Prerequisites

Install these tools before working on the repository:

| Tool | Version checked | Used for |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.16.5 | fmt, validate and `terraform test` |
| [TFLint](https://github.com/terraform-linters/tflint) | 0.64.0 | lint, with `.tflint.hcl` |
| [terraform-docs](https://terraform-docs.io/user-guide/installation/) | 0.24.0 | the reference between `BEGIN_TF_DOCS` and `END_TF_DOCS` in each module README, with `.terraform-docs.yml` |
| [pre-commit](https://pre-commit.com/#install) | 4.5.1 | runs the hooks of `.pre-commit-config.yaml` |

Working on a module takes Terraform 1.7 or later: its tests use
`mock_provider`, and from 1.6 down `terraform init` fails in the module folder.
Callers of a module only need the Terraform version in the module's own
requirements, since Terraform does not read the tests of a child module.

### Checks

Install the hooks once per clone, so that fmt, validate, tflint and
terraform-docs run on each commit, in every folder the commit touches:

```bash
pre-commit install
```

Before pushing, run the hooks on every file, then the tests of the module you
changed, which are not a hook:

```bash
pre-commit run --all-files
terraform -chdir=cloudflare-dns init -backend=false
terraform -chdir=cloudflare-dns test
```

The [Checks](.github/workflows/checks.yml) workflow runs the same hooks, then
the tests of every module, on each pull request and each push to `main`, with
the tool versions listed above. Three more jobs validate each module with the
bottom of its requirements: `cloudflare-dns` with Terraform 1.3.10 and
provider 5.27.0, `cloudflare-zero-trust-access` and
`cloudflare-zero-trust-networks` with Terraform 1.3.10 and provider 5.28.0.
The branch protection of `main` lists the jobs a pull request must pass
before it is merged.

These tests mock the provider, so they cannot see what Cloudflare does with
a value. A module can also hold tests against the real API, in `tests-real`,
which `terraform test` runs only when asked. They create real records and
destroy them at the end: run them before a provider upgrade or a release.
For `cloudflare-dns`, the zone must exist, and the tests only touch records
under `tf-test.<zone>`:

```bash
export CLOUDFLARE_API_TOKEN=...
terraform -chdir=cloudflare-dns test -test-directory=tests-real -var name=example.com -var account_id=...
```

For `cloudflare-zero-trust-access`, `tests-real` is a configuration that
calls the module, as a user would, with objects that refer to each other
through its outputs, which a test file cannot write. Apply it, plan again,
which must show no change, and destroy it. The account's Zero Trust
organization must exist; the objects are named `tf-test-ci-*`, under
`tf-test-ci.<zone>`, and the settings of the account are left alone:

```bash
export CLOUDFLARE_API_TOKEN=...
cd cloudflare-zero-trust-access/tests-real
terraform init
terraform apply -var account_id=... -var zone=example.com
terraform plan -detailed-exitcode -var account_id=... -var zone=example.com
terraform destroy -var account_id=... -var zone=example.com
```

`cloudflare-zero-trust-networks/tests-real` works the same way, on the same
account: the tunnels, virtual networks and WARP Connectors are named
`tf-test-ci-*`, the routes take `10.252.0.0/16` and `fd00:252::/48`, and the
connectivity settings of the account are left alone. Cloudflare never returns
the secret of the test tunnel: pass the same one to each command.

```bash
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_tunnel_secret="$(openssl rand -base64 32)"
cd cloudflare-zero-trust-networks/tests-real
terraform init
terraform apply -var account_id=... -var zone=example.com
terraform plan -detailed-exitcode -var account_id=... -var zone=example.com
terraform destroy -var account_id=... -var zone=example.com
```

The [Real API tests](.github/workflows/tests-real.yml) workflow runs them
every day with the newest provider 5.x, and on demand from the Actions tab.
For the Zero Trust modules, a second plan with a change fails the run: that
is a provider that drifts from what it applied. It reads these repository
secrets:

| Secret | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | a token for the test zone only: Zone → DNS → Edit and Zone → Zone → Read |
| `TEST_ZONE` | the name of the test zone |
| `TEST_ACCOUNT_ID` | the ID of its account |
| `ZERO_TRUST_TEST_API_TOKEN` | a token for the Zero Trust test account only, with the permissions in the [Quick start](cloudflare-zero-trust-access/README.md#quick-start) of `cloudflare-zero-trust-access`, plus Cloudflare Tunnel → Edit and Cloudflare One Connector: WARP → Edit for `cloudflare-zero-trust-networks` |
| `ZERO_TRUST_TEST_ACCOUNT_ID` | the ID of that account |
| `ZERO_TRUST_TEST_ZONE` | the name of a zone in that account |

Before the tests, the workflow deletes what a run cut short before its
cleanup leaves behind: `tf-test.<zone>` and every name under it, the Access
objects named `tf-test-ci-*`, and the tunnels, WARP Connectors and virtual
networks named `tf-test-ci-*` with the routes that use them. Keep these names
for this workflow only.

### Release a module

Each pull request writes its changes under `[Unreleased]` in the
`CHANGELOG.md` of the module it touches, and takes a
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) title
scoped by the module, such as `feat(cloudflare-dns): …`. On each push to
`main`, the [Release](.github/workflows/release.yml) workflow releases each
module on its own.

When the newest dated section of a module's `CHANGELOG.md`, such as
`## [1.0.0] - 2026-10-18`, has no tag yet, the workflow tags the commit that
dated it, `<module>/v1.0.0`: that is how a first version, or any chosen
version, is released. Otherwise the commits since the module's last tag that
touch its folder, merge commits left out, give the version, the strongest one
winning:

| Commits since the last tag | Version |
|---|---|
| a `!` after the type, such as `refactor(cloudflare-dns)!:`, or a `BREAKING CHANGE:` footer | major, a minor one before v1.0.0 |
| `feat:` | minor |
| `fix:` or `perf:` | patch |
| only other types, such as `ci:`, `docs:`, `test:` or `chore:` | none: the changes wait for the next version |

The workflow then dates the `[Unreleased]` section, bumps the module's tag in
the `?ref=` of the READMEs and in the *Latest release* column above, and
commits `chore(<module>): release vX.Y.Z`. It fails for a module whose
`[Unreleased]` is empty, and still releases the others.

It pushes that commit to `main` with the deploy key of the
`RELEASE_DEPLOY_KEY` secret, which the rule that protects `main` lets
through, and the tags with the workflow's own token. It then creates each
GitHub release, with the module's section of its `CHANGELOG.md` as notes, and
starts the module's mirror workflow, such as
[Mirror cloudflare-dns](.github/workflows/mirror-cloudflare-dns.yml), which
publishes the release to `terraform-cloudflare-dns` as `vX.Y.Z`, where the
Terraform Registry picks it up. A mirror pushes with a deploy key that can
write to its repository only, kept in a secret per module, such as
`MIRROR_DEPLOY_KEY_CLOUDFLARE_DNS`, and never overwrites a version already
published. A tag pushed by hand, `<module>/vX.Y.Z`, also gets its release
and its mirror.

## License

[MIT](LICENSE)
