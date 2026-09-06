# Settings applied to every repository in the organization.
# Squash-only merge strategy: keeps history linear and branches tidy.
locals {
  # Topic added to every managed repository, to distinguish it from
  # non-managed repos in the org.
  managed_topic = "terraform-managed"

  # Referenced by name (not via github_repository.this["template-repo"]) in
  # the `template` block below: since template-repo is itself one of the
  # for_each instances of github_repository.this, referencing another
  # instance of the same resource from within it is a self-reference -
  # OpenTofu builds the dependency graph per-resource, not per-instance, so
  # that would make github_repository.this depend on itself and cycle.
  template_repository_name = "template-repo"

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
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "fizz-buzz" = {
      description  = ""
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["java", "ci-cd"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "milanoid-labs-terraform" = {
      description  = "OpenTofu code to manage the milanoid-labs GitHub organization"
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["tofu", "terraform"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "devops-study-app" = {
      description  = "(My) Python project for Mischa's DevOps Masterclass"
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["python", "uv"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "milanoid-aws-terraform" = {
      description  = "OpenTofu code for my personal ECS lab in AWS"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["tofu", "terraform", "aws", "ecs"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "LFS256-code" = {
      description  = "Code for DevOps and Workflow Management with Argo (LFS256)"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["argo", "gitops"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "import-me-tofu" = {
      description  = "test tofu import feature"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = []
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "milanoid-net-terraform" = {
      description  = "Cloudflare milanoid.net Terraform configuration"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = ["tofu", "terraform", "cloudflare", "dns"]
      is_template  = false
      auto_init    = false
      use_template = false
    }
    "home-dashboard" = {
      description  = "Mobile-friendly dashboard for my Eaton xComfort smart home controller"
      visibility   = "public"
      has_issues   = true
      has_projects = true
      has_wiki     = false
      topics       = ["python", "uv", "home-automation"]
      is_template  = false
      auto_init    = false
      use_template = true
    }
    "template-repo" = {
      description  = "Template used to scaffold new milanoid-labs repositories"
      visibility   = "public"
      has_issues   = true
      has_projects = false
      has_wiki     = false
      topics       = []
      is_template  = true
      auto_init    = true
      use_template = false
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

  is_template = each.value.is_template
  auto_init   = each.value.auto_init

  # Create from template-repo instead of from scratch, so the repo starts
  # with a default branch/commit already in place (see #36: pushing
  # CODEOWNERS to a repo with no branches yet fails with a 404).
  dynamic "template" {
    for_each = each.value.use_template ? [1] : []
    content {
      owner      = var.github_organization
      repository = local.template_repository_name
    }
  }

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

resource "github_workflow_repository_permissions" "home_dashboard" {
  repository                   = github_repository.this["home-dashboard"].name
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
  renovate_repositories    = ["homelab-cluster", "devops-study-app", "home-dashboard"]
}

resource "github_app_installation_repository" "renovate" {
  for_each = toset(local.renovate_repositories)

  installation_id = local.renovate_installation_id
  repository      = github_repository.this[each.key].name
}
