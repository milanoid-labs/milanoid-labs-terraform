terraform {
  required_version = ">= 1.12.0"

  backend "s3" {
    bucket       = "milanoid-labs-terraform-tofu-state"
    key          = "prod/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    profile      = "milanoid" # this will work on my machine only, if tofu running in CI it won't work
    encrypt      = true       # to make it explicit, S3 default encryption is neabled in AWS 
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
