provider "aws" {
  region = "ap-southeast-1"  # Change to your desired region
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

# Define local variables
locals {
  prefix = "yyf-app"  # Replace with your desired prefix
}

# Fetch current AWS account ID
data "aws_caller_identity" "current" {}

# Fetch current AWS region
data "aws_region" "current" {}

# Create an ECR repository
resource "aws_ecr_repository" "ecr" {
  name                 = "${local.prefix}-ecr"
  force_delete         = true

  # Enable encryption for the ECR repository
  encryption_configuration {
    encryption_type = "KMS"  # Use AWS KMS for encryption
    # kms_key        = "arn:aws:kms:ap-southeast-1:123456789012:key/your-kms-key-id"  # Optional: Specify a custom KMS key ARN
  }

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create a security group for the ECS service
resource "aws_security_group" "ecs_service" {
  name        = "${local.prefix}-ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = "vpc-0916e29d8add9bb15"  # Replace with your VPC ID

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere (adjust as needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# Create the ECS cluster and service
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs"

  # Configure Fargate capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  # Define the ECS service
  services = {
    my-app-task = {  # Task definition and service name
      cpu    = 512
      memory = 1024

      # Container definition
      container_definitions = jsonencode([
        {
          name      = "my-app-container"  # Container name
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

      # Subnet IDs (replace with your subnet IDs)
      subnet_ids = [
        "subnet-0bbee1ca446e01642",  # Replace with your subnet ID
        "subnet-0bbee1ca446e01643"   # Replace with your subnet ID
      ]

      # Security group IDs (use the one created above)
      security_group_ids = [
        aws_security_group.ecs_service.id
      ]
    }
  }
}