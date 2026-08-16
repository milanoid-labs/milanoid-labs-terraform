terraform {
  required_version = ">= 1.12.0"

  backend "s3" {
    bucket       = "milanoid-labs-terraform-tofu-state"
    key          = "bootstrap/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    profile      = "milanoid" # this will work on my machine only, if tofu running in CI it won't work
    encrypt      = true       # to make it explicit, S3 default encryption is enabled in AWS
  }



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

resource "aws_iam_openid_connect_provider" "github__milanoid_labs_milanoid_labs_terraform" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_actions_plan" {
  name = "milanoid-labs-terraform-ci-plan"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github__milanoid_labs_milanoid_labs_terraform.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:milanoid-labs/milanoid-labs-terraform:pull_request"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_plan_s3" {
  name = "state-read-only"
  role = aws_iam_role.github_actions_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state"
        Condition = {
          StringLike = {
            "s3:prefix" = "prod/*"
          }
        }
      },
      {
        Sid      = "ReadState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state/prod/terraform.tfstate"
      },
      {
        Sid    = "LockState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state/prod/terraform.tfstate.tflock"
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_apply" {
  name = "milanoid-labs-terraform-ci-apply"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github__milanoid_labs_milanoid_labs_terraform.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:milanoid-labs/milanoid-labs-terraform:ref:refs/heads/main"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_apply_s3" {
  name = "state-read-apply"
  role = aws_iam_role.github_actions_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state"
        Condition = {
          StringLike = {
            "s3:prefix" = "prod/*"
          }
        }
      },
      {
        Sid    = "ReadState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state/prod/terraform.tfstate"
      },
      {
        Sid    = "LockState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::milanoid-labs-terraform-tofu-state/prod/terraform.tfstate.tflock"
      },
    ]
  })
}


output "plan_role_arn" {
  value = aws_iam_role.github_actions_plan.arn
}

output "apply_role_arn" {
  value = aws_iam_role.github_actions_apply.arn
}
