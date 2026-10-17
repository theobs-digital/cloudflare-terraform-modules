# cloudflare-terraform-modules

Terraform modules for [Cloudflare](https://www.cloudflare.com/), on top of the
[`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
provider. The modules stay thin: each input maps to a provider resource and
keeps its attribute names, so whoever knows the provider knows the module.

## Modules

| Module | Manages | Latest release |
|---|---|---|
| [`cloudflare-dns`](cloudflare-dns) | A DNS zone: the zone, its records, its DNS settings and DNSSEC | [`cloudflare-dns/v1.1.0`](cloudflare-dns/CHANGELOG.md) |

## Usage

Each module lives in its own folder and is released on its own, under a tag
prefixed by the folder name, such as `cloudflare-dns/v1.0.0`. Reference a
module by Git, with the folder after `//` and the tag in `ref`:

```hcl
module "dns" {
  source = "github.com/theobs-digital/cloudflare-terraform-modules//cloudflare-dns?ref=cloudflare-dns/v1.1.0"

  # ...
}
```

Terraform clones the repository over HTTPS, which needs no credentials. To
clone over SSH instead, write the source as
`git::ssh://git@github.com/theobs-digital/cloudflare-terraform-modules.git//cloudflare-dns?ref=cloudflare-dns/v1.1.0`.

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
module by module, and each module records its changes in its own
`CHANGELOG.md`. Always set `ref` to a tag: without it, Terraform takes the
latest commit of the default branch.

The modules are not published on the Terraform Registry, which requires one
repository per module.

## Development

### Prerequisites

Install these tools before working on the repository:

| Tool | Version checked | Used for |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.16.5 | fmt, validate and `terraform test` |
| [TFLint](https://github.com/terraform-linters/tflint) | 0.64.0 | lint, with `.tflint.hcl` |
| [terraform-docs](https://terraform-docs.io/user-guide/installation/) | 0.24.0 | the tables between `BEGIN_TF_DOCS` and `END_TF_DOCS` in each module README |
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

### Release a module

Update the module's `CHANGELOG.md`, then tag the commit with the module prefix
and push the tag:

```bash
git tag cloudflare-dns/v1.0.0
git push origin cloudflare-dns/v1.0.0
```

## License

[MIT](LICENSE)
