# https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest?tab=inputs

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.4"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.60.0"
    }
  }
}

provider "aws" {
  profile = "milanoid"
  region  = "eu-central-1"
}

output "s3_bucket_arn" {
  value = module.s3-bucket.s3_bucket_arn
}
