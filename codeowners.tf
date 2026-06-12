locals {
  codeowners_content = "* @milanoid\n"
}

# Pushes a .github/CODEOWNERS file to every managed repository, including
# this one.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "codeowners" {
  for_each = local.repositories

  repository          = github_repository.this[each.key].name
  branch              = github_repository.this[each.key].default_branch
  file                = ".github/CODEOWNERS"
  content             = local.codeowners_content
  commit_message      = "Add CODEOWNERS"
  commit_author       = "milanoid"
  commit_email        = "milanvojnovic@gmail.com"
  overwrite_on_create = true
}
