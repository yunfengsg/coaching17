terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87.0"  # Use a valid version constraint
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}