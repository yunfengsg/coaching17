provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  prefix = "yyf"  # Replace with your desired prefix
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs"
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    yyf-coaching17-task = {
      cpu    = 512
      memory = 1024
      container_definitions = jsonencode([
        {
          name      = "yyf-coaching17-container"
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          portMappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      ])
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = ["subnet-0bbee1ca446e01642"] # Use quotes for strings
      security_group_ids                 = ["sg-09662e0e5a3857a26"]    # Use quotes for strings
    }
  }
}