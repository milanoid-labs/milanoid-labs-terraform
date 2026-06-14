variable "github_organization" {
  description = "Name of the GitHub organization to manage."
  type        = string
  default     = "milanoid-labs"
}

variable "devops_study_app_pat" {
  description = "PAT used by release-please in the devops-study-app repository. Provide via the TF_VAR_devops_study_app_pat environment variable; never commit a value."
  type        = string
  sensitive   = true
}
