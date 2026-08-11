terraform {
  cloud {
    organization = "milanvojnovic-org"
    workspaces {
      name = "004-demo"
      #project = "default"
    }
  }
}

provider "random" {}

resource "random_pet" "name" {
  length = 3
}

output "random_pet_name" {
  value = random_pet.name.id
}
