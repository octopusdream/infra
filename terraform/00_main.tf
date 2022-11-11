terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.12"
}

# Terraform과 외부 서비스를 연결해주는 기능을 하는 모듈
# AWS, Azure, GCP와 같은 Public Cloud 뿐만 아니라, MySQL, DOcker와 같은 Local Service 등을 지원

provider "aws" {
  alias = "seoul"
  region = var.aws_region
}



