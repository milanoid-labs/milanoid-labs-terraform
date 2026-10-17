# CI access for the other OpenTofu repos in the org: one plan/apply role pair per repo,
# generated from the set below instead of a copied bootstrap/ folder in each repo.
#
# Onboarding a repo: add it here, then `tofu apply` locally (see README.md). Each role
# is scoped to its own state key (<repo>/terraform.tfstate) in the shared bucket, so a
# repo can never read or write another repo's state. Not a single wildcard role: state
# files hold secrets, and org-wide trust would hand them to every repo, present or future.
#
# milanoid-labs-terraform's own roles stay in terraform.tf: its state key layout
# (prod/terraform.tfstate) predates this convention.
# Not yet migrated here: milanoid-tailscale-terraform, milanoid-net-terraform (they
# still have their own bootstrap/aws-oidc; move them with import blocks).
locals {
  # oidc_sub_prefix is the repo's actual OIDC subject prefix. Repos created after
  # 2026-07-15 get GitHub's immutable subject format, which embeds the org and repo IDs
  # (repo:OWNER@ORG_ID/REPO@REPO_ID); older repos keep repo:OWNER/REPO unless opted in.
  # A wrong prefix makes AssumeRoleWithWebIdentity fail for every CI run, so copy it from:
  #   gh api repos/milanoid-labs/<repo>/actions/oidc/customization/sub -q .sub_claim_prefix
  tofu_repos = {
    "nexus-config-terraform" = {
      oidc_sub_prefix = "repo:milanoid-labs@272012797/nexus-config-terraform@1423160851"
    }
  }
}

resource "aws_iam_role" "tofu_repo_plan" {
  for_each = local.tofu_repos

  name = "${each.key}-ci-plan"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github__milanoid_labs_milanoid_labs_terraform.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # Any PR. Fork PRs never get an OIDC token from GitHub, so in practice
            # this is PRs from branches of the repo itself.
            "token.actions.githubusercontent.com:sub" = "${each.value.oidc_sub_prefix}:pull_request"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tofu_repo_plan_s3" {
  for_each = local.tofu_repos

  name = "state-read-only"
  role = aws_iam_role.tofu_repo_plan[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = "${each.key}/*"
          }
        }
      },
      {
        Sid      = "ReadState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${local.bucket_name}/${each.key}/terraform.tfstate"
      },
      {
        # Plan takes the native S3 lock, so it may write the .tflock object only.
        Sid    = "LockState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${local.bucket_name}/${each.key}/terraform.tfstate.tflock"
      },
    ]
  })
}

resource "aws_iam_role" "tofu_repo_apply" {
  for_each = local.tofu_repos

  name = "${each.key}-ci-apply"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github__milanoid_labs_milanoid_labs_terraform.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # Only a push to main, never a PR.
            "token.actions.githubusercontent.com:sub" = "${each.value.oidc_sub_prefix}:ref:refs/heads/main"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tofu_repo_apply_s3" {
  for_each = local.tofu_repos

  name = "state-read-apply"
  role = aws_iam_role.tofu_repo_apply[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = "${each.key}/*"
          }
        }
      },
      {
        Sid    = "ReadWriteState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "arn:aws:s3:::${local.bucket_name}/${each.key}/terraform.tfstate"
      },
      {
        Sid    = "LockState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${local.bucket_name}/${each.key}/terraform.tfstate.tflock"
      },
    ]
  })
}

# Same variable names the copied bootstraps used, so the repos' workflows don't change.
locals {
  tofu_repo_variables = merge([
    for repo in keys(local.tofu_repos) : {
      "${repo}/AWS_REGION"            = { repository = repo, name = "AWS_REGION", value = local.aws_region }
      "${repo}/AWS_TOFU_STATE_BUCKET" = { repository = repo, name = "AWS_TOFU_STATE_BUCKET", value = local.bucket_name }
      "${repo}/AWS_PLAN_ROLE_ARN"     = { repository = repo, name = "AWS_PLAN_ROLE_ARN", value = aws_iam_role.tofu_repo_plan[repo].arn }
      "${repo}/AWS_APPLY_ROLE_ARN"    = { repository = repo, name = "AWS_APPLY_ROLE_ARN", value = aws_iam_role.tofu_repo_apply[repo].arn }
    }
  ]...)
}

resource "github_actions_variable" "tofu_repo" {
  for_each = local.tofu_repo_variables

  repository    = each.value.repository
  variable_name = each.value.name
  value         = each.value.value
}

output "tofu_repo_roles" {
  value = {
    for repo in keys(local.tofu_repos) : repo => {
      plan  = aws_iam_role.tofu_repo_plan[repo].arn
      apply = aws_iam_role.tofu_repo_apply[repo].arn
    }
  }
}
