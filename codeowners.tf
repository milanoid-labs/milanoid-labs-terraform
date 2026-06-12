# Pushes this repo's .github/CODEOWNERS to every other managed repository
# (this repo's own copy is committed directly, since it's already a local
# checkout).
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "codeowners" {
  for_each = { for name in keys(local.repositories) : name => name if name != "milanoid-labs-terraform" }

  repository          = github_repository.this[each.key].name
  branch              = github_repository.this[each.key].default_branch
  file                = ".github/CODEOWNERS"
  content             = file("${path.module}/.github/CODEOWNERS")
  commit_message      = "Add CODEOWNERS"
  commit_author       = "milanoid"
  commit_email        = "milanvojnovic@gmail.com"
  overwrite_on_create = true
}
