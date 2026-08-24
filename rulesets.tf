# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
resource "github_repository_ruleset" "devops_study_app_main" {
  name        = "main"
  repository  = github_repository.this["devops-study-app"].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Allow org admins (e.g. the OpenTofu-managed automation in this repo) to
  # push directly to main, bypassing the pull_request rule below.
  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion = true

    pull_request {}
  }
}
resource "github_repository_ruleset" "homelab_cluster" {
  enforcement = "active"
  name        = "renovate-minimumReleaseAge"
  repository  = "homelab-cluster"
  target      = "branch"

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    required_status_checks {
      do_not_enforce_on_create             = false
      strict_required_status_checks_policy = false

      required_check {
        context        = "renovate/stability-days"
        integration_id = 3219089
      }
    }
  }
}
