# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
resource "github_actions_secret" "devops_study_app_pat" {
  repository      = github_repository.this["devops-study-app"].name
  secret_name     = "DEVOPS_STUDY_APP"
  plaintext_value = var.devops_study_app_pat
}

locals {
  nexus_secret_repository_ids = [
    github_repository.this["devops-study-app"].repo_id,
    github_repository.this["milanoid-labs-terraform"].repo_id
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
