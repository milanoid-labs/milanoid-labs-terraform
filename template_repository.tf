# Seeds template-repo's content. The repo itself (is_template = true,
# auto_init = true) is created via the `local.repositories` map in
# repositories.tf, alongside every other managed repository; CODEOWNERS is
# pushed to it there too, by codeowners.tf's for_each over that same map.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "template_readme" {
  repository          = github_repository.this["template-repo"].name
  branch              = github_repository.this["template-repo"].default_branch
  file                = "README.md"
  content             = <<-EOT
    # template-repo

    Template repository for new milanoid-labs projects. Generate a new repo
    from this template, then replace this README.
  EOT
  commit_message      = "Add README"
  commit_author       = "milanoid"
  commit_email        = "1455822+milanoid@users.noreply.github.com"
  overwrite_on_create = true
}

resource "github_repository_file" "template_gitignore" {
  repository          = github_repository.this["template-repo"].name
  branch              = github_repository.this["template-repo"].default_branch
  file                = ".gitignore"
  content             = <<-EOT
    .DS_Store
    .idea/
    .vscode/
  EOT
  commit_message      = "Add .gitignore"
  commit_author       = "milanoid"
  commit_email        = "1455822+milanoid@users.noreply.github.com"
  overwrite_on_create = true
}
