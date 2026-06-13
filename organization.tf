# Organization-wide GitHub Actions workflow permissions.
# default_workflow_permissions must be "write" at the org level so that
# individual repositories are allowed to set their own write permissions.
# If the org enforces "read", the repo-level setting is greyed out and ignored.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_workflow_permissions
resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug            = var.github_organization
  default_workflow_permissions = "write"
}

# Organization-wide settings for milanoid-labs.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_settings
resource "github_organization_settings" "this" {
  billing_email = "milanvojnovic@gmail.com"
  name          = "Milanoid Labs"
  description   = ""
  location      = "Czech Republic"

  has_organization_projects = true
  has_repository_projects   = true

  default_repository_permission           = "read"
  members_can_create_repositories         = true
  members_can_create_public_repositories  = true
  members_can_create_private_repositories = true

  web_commit_signoff_required = false
}
