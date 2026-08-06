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
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion = true

    pull_request {}

    required_status_checks {
      required_check {
        context        = "Test Backend"
        integration_id = 15368
      }

      required_check {
        context        = "Test Frontend"
        integration_id = 15368
      }
    }
  }
}
