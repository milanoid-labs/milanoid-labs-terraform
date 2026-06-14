# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
resource "github_actions_secret" "devops_study_app_pat" {
  repository      = github_repository.this["devops-study-app"].name
  secret_name     = "DEVOPS_STUDY_APP"
  plaintext_value = var.devops_study_app_pat
}
