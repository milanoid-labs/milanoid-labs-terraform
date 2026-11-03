import {
  to = github_repository.this["import-me-tofu"]
  id = "import-me-tofu"
}

import {
  to = github_repository_ruleset.homelab_cluster
  id = "homelab-cluster:21289334"
}

# kubevirt-scaleset was granted to the Renovate app by hand (homelab-cluster #795);
# adopt the existing grant instead of creating it.
import {
  to = github_app_installation_repository.renovate["kubevirt-scaleset"]
  id = "119949905:kubevirt-scaleset"
}
