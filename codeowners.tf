locals {
  codeowners_content = "* @milanoid\n"
}

# Pushes a CODEOWNERS file to every managed repository except this one (whose
# copy is committed directly, since it's already a local checkout).
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "codeowners" {
  for_each = toset(["homelab-cluster", "fizz-buzz", "devops-study-app"])

  repository          = github_repository.this[each.key].name
  branch              = github_repository.this[each.key].default_branch
  file                = ".github/CODEOWNERS"
  content             = local.codeowners_content
  commit_message      = "Add CODEOWNERS"
  commit_author       = "milanoid"
  commit_email        = "milanvojnovic@gmail.com"
  overwrite_on_create = true
}
