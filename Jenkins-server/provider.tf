#Handling the statefile and aws provider
terraform {
  cloud {
    organization = "Sanusibit"

    workspaces {
      name = "Altschool"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}



provider "aws" {
    region = "eu-west-2"
}
