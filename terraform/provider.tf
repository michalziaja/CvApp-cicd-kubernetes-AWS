terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.25.0"
    }
  }

  backend "s3" {
    bucket = "github-actions-cicd-1959"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }

  required_version = ">= 1.6.3"
} 