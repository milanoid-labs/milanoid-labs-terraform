# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
resource "github_actions_secret" "devops_study_app_pat" {
  repository      = github_repository.this["devops-study-app"].name
  secret_name     = "DEVOPS_STUDY_APP"
  plaintext_value = var.devops_study_app_pat
}

resource "github_actions_secret" "home_dashboard_pat" {
  repository      = github_repository.this["home-dashboard"].name
  secret_name     = "HOME_DASHBOARD"
  plaintext_value = var.home_dashboard_pat
}

locals {
  nexus_secret_repository_ids = [
    github_repository.this["devops-study-app"].repo_id,
    github_repository.this["milanoid-labs-terraform"].repo_id,
    github_repository.this["home-dashboard"].repo_id
  ]
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_secret
resource "github_actions_organization_secret" "nexus_username" {
  secret_name             = "NEXUS_USERNAME"
  visibility              = "selected"
  selected_repository_ids = local.nexus_secret_repository_ids
  plaintext_value         = var.nexus_username
}

resource "github_actions_organization_secret" "nexus_password" {
  secret_name             = "NEXUS_PASSWORD"
  visibility              = "selected"
  selected_repository_ids = local.nexus_secret_repository_ids
  plaintext_value         = var.nexus_password
}

# Dependabot-triggered workflow runs only receive Dependabot secrets, never
# Actions secrets, so the Sonar scan on Dependabot PRs needs its own copy of
# SONAR_TOKEN. Same repository scope as the (manually managed) SONAR_TOKEN
# Actions organization secret. The token must only have the Execute Analysis
# permission, since Dependabot PRs run unreviewed upstream code.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/dependabot_organization_secret
resource "github_dependabot_organization_secret" "sonar_token" {
  secret_name             = "SONAR_TOKEN"
  visibility              = "selected"
  selected_repository_ids = [github_repository.this["fizz-buzz"].repo_id]
  plaintext_value         = var.sonar_token
}
