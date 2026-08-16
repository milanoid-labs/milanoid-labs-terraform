terraform {
  required_version = ">= 1.12.0"

  backend "s3" {
    bucket       = "milanoid-labs-terraform-tofu-state"
    key          = "prod/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    # profile      = "milanoid" # uncomment this if running locally
    encrypt = true # to make it explicit, S3 default encryption is enabled in AWS
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
