locals {
  # Repository topic -> Dependabot package-ecosystem. Each ecosystem has its
  # own `updates:` entry template in dependabot/<ecosystem>.yaml.
  dependabot_topic_ecosystems = {
    java   = "maven"
    python = "uv"
  }

  # Ecosystems per opted-in repository (`dependabot = true` in
  # local.repositories), derived from its topics. github-actions is always
  # included. Repos updated by Renovate (local.renovate_repositories) should
  # stay opted out to avoid duplicate update PRs.
  dependabot_repositories = {
    for name, repo in local.repositories : name => distinct(concat(
      ["github-actions"],
      [for topic in repo.topics : local.dependabot_topic_ecosystems[topic] if contains(keys(local.dependabot_topic_ecosystems), topic)],
    )) if repo.dependabot
  }

  # GitHub reads a single .github/dependabot.yml per repository, so the
  # per-ecosystem templates are merged into one `updates:` list.
  dependabot_content = {
    for name, ecosystems in local.dependabot_repositories : name => join("", concat(
      ["version: 2\nupdates:\n"],
      [for ecosystem in ecosystems : "  ${indent(2, chomp(file("${path.module}/dependabot/${ecosystem}.yaml")))}\n"],
    ))
  }
}

# Pushes a .github/dependabot.yml (version updates only) to every opted-in
# repository.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "dependabot" {
  for_each = local.dependabot_content

  repository          = github_repository.this[each.key].name
  branch              = github_repository.this[each.key].default_branch
  file                = ".github/dependabot.yml"
  content             = each.value
  commit_message      = "Add Dependabot config"
  commit_author       = "milanoid"
  commit_email        = "1455822+milanoid@users.noreply.github.com"
  overwrite_on_create = true

  lifecycle {
    precondition {
      condition     = can(yamldecode(each.value))
      error_message = "Generated dependabot.yml for ${each.key} is not valid YAML."
    }
  }
}
