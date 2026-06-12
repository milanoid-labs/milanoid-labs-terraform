# milanoid-labs-terraform

OpenTofu code that manages the [milanoid-labs](https://github.com/milanoid-labs) GitHub
organization: organization-wide settings and per-repository settings such as merge
strategies, branch protections, and feature toggles.

## Usage

Authenticate with a GitHub token that has `admin:org` and `repo` scopes (e.g. via
`gh auth token`), then export it:

```sh
export GITHUB_TOKEN=$(gh auth token)
```

Initialize and apply:

```sh
tofu init
tofu plan
tofu apply
```

## Structure

- `organization.tf` - organization-wide settings (default permissions, member
  privileges, security settings).
- `repositories.tf` - per-repository settings, including the squash-only merge
  strategy applied to every managed repository.
- `rulesets.tf` - per-repository branch rulesets (e.g. branch protection rules).
- `codeowners.tf` - pushes this repo's `.github/CODEOWNERS` file to every
  other managed repository.

## Adding a new repository

Add an entry to the `local.repositories` map in `repositories.tf`, then either let
OpenTofu create it (`tofu apply`) or, if it already exists, import it:

```sh
tofu import 'github_repository.this["<repo-name>"]' <repo-name>
```

## Conventions

Every repository in `local.repositories` is tagged with the `terraform-managed`
GitHub topic, so managed repos can be distinguished from other repos in the org
at a glance.

Every managed repository has a `.github/CODEOWNERS` file listing `@milanoid` as
owner of everything. For the other repos this is pushed by `codeowners.tf`; this
repo's own copy is committed directly and kept in sync with that content
manually.

## State

State is stored locally (`terraform.tfstate`, gitignored). Back it up before making
changes, and consider migrating to a remote backend (e.g. HCP Terraform) if more
than one person manages this organization.
