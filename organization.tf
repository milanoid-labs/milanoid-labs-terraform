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

  # Left disabled to avoid locking out org members who don't have 2FA configured.
  two_factor_requirement_enabled = false
}
