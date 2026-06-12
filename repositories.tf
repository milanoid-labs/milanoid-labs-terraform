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
      has_wiki     = true
      topics       = []
    }
    "milanoid-labs-terraform" = {
      description  = "OpenTofu code to manage the milanoid-labs GitHub organization"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = []
    }
    "devops-study-app" = {
      description  = "(My) Python project for Mischa's DevOps Masterclass"
      visibility   = "private"
      has_issues   = true
      has_projects = true
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
