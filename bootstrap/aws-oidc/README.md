# bootstrap/aws-oidc

Provisions what `.github/workflows/tofu-plan.yaml` and `tofu-apply.yaml` need to
authenticate to AWS: a GitHub OIDC identity provider and two IAM roles. This
module is applied **locally only**, by a human, never by CI — see
[Why this is separate](#why-this-is-separate-and-applied-locally) below.

## Why OIDC instead of static AWS keys

The obvious alternative — an IAM user with an access key + secret key pasted into
GitHub as repo secrets — works, but that credential is durable: it doesn't expire,
and if it's ever exposed (a bad log line, a compromised action or provider mid-job,
anything) it keeps working until someone notices and manually rotates it.

OIDC federation avoids ever creating that key pair:

1. For every workflow run, GitHub can mint a short-lived, signed token asserting
   claims about that specific run — which repo, which branch/event, etc. This
   requires no setup on the GitHub side beyond requesting it
   (`permissions: id-token: write` in the workflow).
2. AWS is told to trust tokens signed by GitHub (the
   `aws_iam_openid_connect_provider` resource below) — public-key verification, no
   secret exchanged, comparable to how TLS certificate trust works.
3. Each IAM role's trust policy (`assume_role_policy`) checks the token's claims
   before allowing `sts:AssumeRoleWithWebIdentity` — in particular the `sub`
   claim, which encodes *which* repo and *which* event type the token was minted
   for. A token from any other repo, or from the wrong event type, is rejected.
4. AWS hands back credentials valid for about an hour. Nothing is stored anywhere;
   the whole exchange happens fresh on every job.

This works identically whether the runner triggering it is self-hosted or
GitHub-hosted, ephemeral or persistent — the token is minted by GitHub's control
plane, not by the runner machine.

## What this creates

- **`aws_iam_openid_connect_provider`** for `token.actions.githubusercontent.com`,
  audience `sts.amazonaws.com`. `thumbprint_list` is omitted — AWS manages the CA
  thumbprint automatically for well-known providers like GitHub's.
- **Two IAM roles**, because `plan` and `apply` need different privilege levels
  and different sets of GitHub events should be able to assume each:
  - `milanoid-labs-terraform-ci-plan` — trust policy only accepts tokens whose
    `sub` claim is `repo:milanoid-labs/milanoid-labs-terraform:pull_request`
    (i.e. any PR, including from forks — this is deliberately broad, since the
    repo is public and a plan on a fork PR is expected). Permissions are
    read-only: `s3:ListBucket` (scoped to the `prod/*` prefix),
    `s3:GetObject` on the state file itself, and `s3:GetObject`/`PutObject`/
    `DeleteObject` scoped *only* to the state's `.tflock` object — enough to
    take/release the native S3 lock during `tofu plan` without ever being able to
    write state content.
  - `milanoid-labs-terraform-ci-apply` — trust policy only accepts tokens whose
    `sub` claim is `repo:milanoid-labs/milanoid-labs-terraform:ref:refs/heads/main`
    (i.e. only a `push` to `main` — never a PR, from a fork or otherwise).
    Permissions add `s3:PutObject` on the state file itself.
  - Both scoped to the exact state bucket ARN and `prod/terraform.tfstate*`
    object ARN — never account-wide S3 access. No `dynamodb:*` permissions
    needed, since the backend uses native S3 locking (`use_lockfile = true`),
    not a DynamoDB lock table.
- **`github_actions_variable` resources** publishing `AWS_REGION`,
  `AWS_TOFU_STATE_BUCKET`, `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN` as repo
  variables on `milanoid-labs-terraform`, referencing the role resources
  directly — so there's no manual copy-paste of an ARN anywhere to go stale if a
  role is ever recreated.

## Why this is separate and applied locally

This module's whole purpose is to grant CI its AWS credentials — which means CI
can never be the one to apply it: a workflow run has no credentials until this
module has already created them. Rather than clicking through the AWS Console by
hand (which would work, but leaves no diff/review/history), this stays real
Terraform, just with a human running `tofu apply` locally instead of a workflow.
This is the same reasoning as why the state S3 bucket itself was created manually
via the AWS Console rather than being managed by this repo's main config — the
thing a system depends on to function can't also depend on that system already
working.

State for this module lives in the same S3 bucket as the main config, under a
separate key (`bootstrap/terraform.tfstate`), so it isn't stranded on one laptop.

## Applying it

Unlike the root config, this module's `provider "aws"`/backend blocks hardcode
`profile = "milanoid"` directly — no need to export `AWS_PROFILE`, since (unlike
the root config) this one is never meant to run anywhere but locally:

```sh
tofu init
tofu plan
tofu apply
```

Re-run this only when the trust policy or permissions genuinely need to change
(e.g. adding a new consumer repo, tightening a permission). CI must never modify
its own trust root — if that were ever automated, a compromised CI run could grant
itself broader AWS access with nothing outside the loop able to stop it.
