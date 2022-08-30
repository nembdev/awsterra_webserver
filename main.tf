terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28.0"
    }
  }

  required_version = ">1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main_VPC"
  }
}