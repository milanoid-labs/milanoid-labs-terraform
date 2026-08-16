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

The state backend no longer hardcodes an AWS profile (see [State](#state) below),
so also export the profile to use locally:

```sh
export AWS_PROFILE=milanoid
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

## CI/CD

Two workflows automate `tofu plan`/`apply` on the `homelab-runners` self-hosted
runner:

- **`.github/workflows/tofu-plan.yaml`** — runs on every PR against `main`. Reads
  real state and posts a `tofu plan` diff, but only ever with **read-only** AWS
  access, so even a malicious fork PR can't mutate anything.
- **`.github/workflows/tofu-apply.yaml`** — runs on every push to `main` (i.e.
  after a PR merges). Plans and applies with write access to state.

Both authenticate to AWS via **GitHub OIDC**, not static access keys: each job
requests a short-lived token from GitHub, which an AWS IAM role trusts (scoped to
this exact repo, and further restricted per-role to *which* GitHub event can use
it — see below), and exchanges for temporary credentials. Nothing durable is ever
stored as an AWS secret in GitHub. There's also no manual-approval gate (e.g. a
GitHub Environment) in front of `apply` — that was considered and deliberately
skipped, since three independent layers already gate what reaches it: the
required-PR-review-to-merge ruleset (`rulesets.tf`), the apply role's IAM trust
policy (only tokens from `push`es to `main` can assume it), and the workflow's own
`push: branches: [main]` trigger.

The two AWS IAM roles this depends on are provisioned by a **separate** Terraform
module, [`bootstrap/aws-oidc/`](bootstrap/aws-oidc/), applied **locally only** —
never by CI. See that module's own README for the full explanation, but in short:
CI's own credentials can't be created by a CI run that doesn't have credentials
yet, so this one root module is deliberately outside the automation, the same way
the state S3 bucket itself isn't Terraform-managed by this repo's main config
either.

That module also publishes the role ARNs and a couple of other values as **repo
variables** (Terraform-managed, so they can't drift from the real ARNs):
`AWS_REGION`, `AWS_TOFU_STATE_BUCKET`, `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN`.
A few **repo secrets** are manually created (not Terraform-managed, for the same
bootstrap reasons as the AWS roles) and referenced by the workflows:

- `TF_ADMIN_GITHUB_TOKEN` — a dedicated classic PAT (`admin:org` + `repo`) used
  to authenticate the `github` provider in CI. Deliberately not a shared/reused
  personal token — see the [Secrets](#secrets) section below for why.
- `TF_VAR_devops_study_app_pat` — the same value used locally (see
  [Secrets](#secrets)), supplied to CI the same way.
- `NEXUS_USERNAME` / `NEXUS_PASSWORD` — already existing organization secrets
  (declared in `secrets.tf`), whose visibility now also includes this repo itself
  so the workflows can read them.

`playground/` and `bootstrap/aws-oidc/` are intentionally excluded from both
workflows — only the repo root is ever planned/applied by CI.

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

### The CI PAT (`TF_ADMIN_GITHUB_TOKEN`)

CI authenticates the `github` provider with its own dedicated classic PAT
(`admin:org` + `repo` — the same scopes as the local `GITHUB_TOKEN` in
[Usage](#usage), not the `devops_study_app_pat` above), not a reused personal
token (e.g. `gh auth token`). A personal token's lifecycle isn't CI's to control —
it can rotate or change scope outside of CI's knowledge — and reusing it means a
leak of the CI secret compromises the maintainer's entire GitHub identity, not
just this repo's automation. A dedicated token is independently scoped,
independently revocable, and attributable to "CI" rather than blended with
interactive activity in the audit log. It's created under the maintainer's
personal account (organizations can't own PATs themselves; org membership grants
the token permission to act at the org level via `admin:org`), and stored only
as a repo secret on `milanoid-labs-terraform` — see [CI/CD](#cicd).

## State

In backend AWS S3 bucket. The bucket was created manually via AWS Console. It's a general type, private, versioned and encrypted (SSE-S3/AES256).

The backend block (`terraform.tf`) doesn't hardcode an AWS profile — it relies on
the standard AWS credential chain, so the same config works both locally (via
`AWS_PROFILE=milanoid`, exported per the [Usage](#usage) section) and in CI (via
OIDC-derived temporary credentials, see [CI/CD](#cicd)) without any code
differences between the two.
