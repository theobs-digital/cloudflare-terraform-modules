# cloudflare-terraform-modules

Terraform modules for [Cloudflare](https://www.cloudflare.com/), on top of the
[`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
provider. The modules stay thin: each input maps to a provider resource and
keeps its attribute names, so whoever knows the provider knows the module.

## Modules

| Module | Manages | Terraform Registry | Latest release |
|---|---|---|---|
| [`cloudflare-dns`](cloudflare-dns) | A DNS zone: the zone, its records, its DNS settings and DNSSEC | [`theobs-digital/dns/cloudflare`](https://registry.terraform.io/modules/theobs-digital/dns/cloudflare) | [`cloudflare-dns/v1.2.0`](cloudflare-dns/CHANGELOG.md) |

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
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-dns?ref=cloudflare-dns/v1.2.0"

  # ...
}
```

Terraform clones the repository over HTTPS, which needs no credentials. To
clone over SSH instead, write the source as
`git::ssh://git@github.com/theobs-digital/cloudflare-terraform-modules.git//cloudflare-dns?ref=cloudflare-dns/v1.2.0`.

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
the tool versions listed above. A second job validates `cloudflare-dns` with
the bottom of its requirements, Terraform 1.3.10 and provider 5.27.0. Both
must pass before a pull request can be merged into `main`.

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

The [Real zone tests](.github/workflows/tests-real.yml) workflow runs them
every day with the newest provider 5.x, and on demand from the Actions tab.
It reads three repository secrets:

| Secret | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | a token for the test zone only: Zone → DNS → Edit and Zone → Zone → Read |
| `TEST_ZONE` | the name of the test zone |
| `TEST_ACCOUNT_ID` | the ID of its account |

Before the tests, the workflow deletes `tf-test.<zone>` and every name under
it, where a run cut short before its cleanup leaves its records. Keep these
names for this workflow only.

### Release a module

Update the module's `CHANGELOG.md`, then tag the commit with the module prefix
and push the tag:

```bash
git tag -a cloudflare-dns/vX.Y.Z -m "cloudflare-dns vX.Y.Z"
git push origin cloudflare-dns/vX.Y.Z
```

The tag also starts the [Mirror cloudflare-dns](.github/workflows/mirror-cloudflare-dns.yml)
workflow, which publishes the release to `terraform-cloudflare-dns` as
`vX.Y.Z`, and the Terraform Registry picks it up from there. It pushes with a
deploy key that can write to that repository only, kept in the
`MIRROR_DEPLOY_KEY` secret, and never overwrites a version already published.

## License

[MIT](LICENSE)
