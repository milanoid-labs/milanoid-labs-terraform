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

## Linting

CI runs `tofu fmt`, `tofu init`, `tofu validate`, and `tflint` on every push/PR to `main` (see
`.github/workflows/lint.yml`). To run the same checks locally:

```sh
brew install opentofu tflint   # or your platform's equivalent

tofu fmt -check -recursive     # checks formatting
tofu init -backend=false       # provider plugins only, no state/backend needed
tofu validate                  # checks config validity
tflint                         # static analysis, see .tflint.hcl
```

## Structure

- `organization.tf` - organization-wide settings (default permissions, member
  privileges, security settings).
- `repositories.tf` - per-repository settings, including the squash-only merge
  strategy applied to every managed repository.
- `rulesets.tf` - per-repository branch rulesets (e.g. branch protection rules).
- `codeowners.tf` - pushes a `.github/CODEOWNERS` file to every managed
  repository, including this one.

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

Every managed repository gets a `.github/CODEOWNERS` file listing `@milanoid`
as owner of everything, created/managed via `codeowners.tf` once `tofu apply`
runs.

## Secrets

`secrets.tf` declares the GitHub Actions secrets used by managed repositories (e.g.
the PAT release-please uses in `devops-study-app` to create release PRs that can
trigger other workflows) and two organization-level secrets, `NEXUS_USERNAME` and
`NEXUS_PASSWORD` (used by devops-study-app to publish artifacts to Nexus, scoped to
that repository only via `selected_repository_ids`). The secret *resources* are
managed here, but their values are never committed.

Since these variables have no default, every `tofu plan`/`tofu apply` needs a value
for each of them. Rather than exporting `TF_VAR_*` env vars every session, copy
`secrets.auto.tfvars.example` to `secrets.auto.tfvars` and fill in real values —
OpenTofu loads `*.auto.tfvars` automatically, and the file is already covered by the
`*.tfvars` entry in `.gitignore`:

```sh
cp secrets.auto.tfvars.example secrets.auto.tfvars
# edit secrets.auto.tfvars with real values
tofu plan
```

(`TF_VAR_devops_study_app_pat`, `TF_VAR_nexus_username`, `TF_VAR_nexus_password` still
work as env vars if you prefer not to keep a values file on disk.)

For the PAT specifically: create a classic PAT (Settings → Developer settings →
Personal access tokens (classic)) with the `repo` and `workflow` scopes, and an expiry
of your choosing.

Because GitHub never returns a secret's value, `tofu plan` will always show a diff
for `plaintext_value` on these resources — this is expected and does not mean the
secret is out of sync.

## State

State is stored locally (`terraform.tfstate`, gitignored). Back it up before making
changes, and consider migrating to a remote backend (e.g. HCP Terraform) if more
than one person manages this organization.
