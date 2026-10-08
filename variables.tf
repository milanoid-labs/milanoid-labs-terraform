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

variable "home_dashboard_pat" {
  description = "PAT used by release-please in the home-dashboard repository. Provide via the TF_VAR_home_dashboard_pat environment variable; never commit a value."
  type        = string
  sensitive   = true
}

variable "nexus_username" {
  description = "Nexus username used by devops-study-app to publish artifacts. Provide via the TF_VAR_nexus_username environment variable; never commit a value."
  type        = string
  sensitive   = true
}

variable "nexus_password" {
  description = "Nexus password used by devops-study-app to publish artifacts. Provide via the TF_VAR_nexus_password environment variable; never commit a value."
  type        = string
  sensitive   = true
}

variable "sonar_token" {
  description = "SonarQube token (Execute Analysis permission only) exposed to Dependabot PR workflows as the SONAR_TOKEN Dependabot organization secret. Provide via the TF_VAR_sonar_token environment variable; never commit a value."
  type        = string
  sensitive   = true
}

variable "sonar_host_url" {
  description = "Base URL of the SonarQube server, exposed to workflows as the SONAR_HOST_URL organization Actions variable."
  type        = string
  default     = "http://sonar.milanoid.net:9000"
}
