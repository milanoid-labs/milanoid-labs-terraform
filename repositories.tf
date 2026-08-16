# Settings applied to every repository in the organization.
# Squash-only merge strategy: keeps history linear and branches tidy.
locals {
  # Topic added to every managed repository, to distinguish it from
  # non-managed repos in the org.
  managed_topic = "terraform-managed"

  merge_strategy = {
    allow_merge_commit          = false
    allow_squash_merge          = true
    allow_rebase_merge          = false
    allow_auto_merge            = true
    delete_branch_on_merge      = true
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "PR_BODY"
  }

  repositories = {
    "homelab-cluster" = {
      description  = "My Homelab Cluster"
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = true
      topics       = ["fluxcd", "kubernetes"]
    }
    "fizz-buzz" = {
      description  = ""
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["java", "ci-cd"]
    }
    "milanoid-labs-terraform" = {
      description  = "OpenTofu code to manage the milanoid-labs GitHub organization"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["tofu", "terraform"]
    }
    "devops-study-app" = {
      description  = "(My) Python project for Mischa's DevOps Masterclass"
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["python", "uv"]
    }
    "milanoid-aws-terraform" = {
      description  = "OpenTofu code for my personal ECS lab in AWS"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["tofu", "terraform", "aws", "ecs"]
    }
    "LFS256-code" = {
      description  = "Code for DevOps and Workflow Management with Argo (LFS256)"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["argo", "gitops"]
    }
    "import-me-tofu" = {
      description  = "test tofu import feature"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = []
    }


  }
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
resource "github_repository" "this" {
  for_each = local.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  topics = concat(each.value.topics, [local.managed_topic])

  allow_merge_commit          = local.merge_strategy.allow_merge_commit
  allow_squash_merge          = local.merge_strategy.allow_squash_merge
  allow_rebase_merge          = local.merge_strategy.allow_rebase_merge
  allow_auto_merge            = local.merge_strategy.allow_auto_merge
  delete_branch_on_merge      = local.merge_strategy.delete_branch_on_merge
  squash_merge_commit_title   = local.merge_strategy.squash_merge_commit_title
  squash_merge_commit_message = local.merge_strategy.squash_merge_commit_message

  lifecycle {
    prevent_destroy = true
  }
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/workflow_repository_permissions
resource "github_workflow_repository_permissions" "devops_study_app" {
  repository                   = github_repository.this["devops-study-app"].name
  default_workflow_permissions = "write"
}

# GitHub App installations in this org and their repository access:
#   - arc-runners-milanoid-labs-org: "All repositories". Intentional, not
#     managed here - the provider has no resource for the installation-wide
#     repository_selection setting itself, only for individual repo grants
#     under "selected" mode.
#   - sonarqube-milanoid-bot: "All repositories". Same as above.
#   - Milanoid Renovate Bot (installation id 119949905): "Only select
#     repositories". Each granted repo is modeled explicitly below.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/app_installation_repository
locals {
  renovate_installation_id = "119949905"
  renovate_repositories    = ["homelab-cluster", "devops-study-app"]
}

resource "github_app_installation_repository" "renovate" {
  for_each = toset(local.renovate_repositories)

  installation_id = local.renovate_installation_id
  repository      = github_repository.this[each.key].name
}
