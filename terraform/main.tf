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
  region              = var.region
}

module "vpc" {
  source              = "./modules/01_vpc"
  vpc_cidr_block      = var.vpc_cidr_block
  alltag              = var.alltag
  region = var.region

  public_subnet_a_cidr_block = var.public_subnet_a_cidr_block
  public_subnet_b_cidr_block = var.public_subnet_b_cidr_block
  public_subnet_c_cidr_block = var.public_subnet_c_cidr_block
  private_subnet_a_cidr_block = var.private_subnet_a_cidr_block
  private_subnet_b_cidr_block = var.private_subnet_b_cidr_block
  private_subnet_c_cidr_block = var.private_subnet_c_cidr_block

  AZ_a = "${var.region}a"
  AZ_b = "${var.region}b"
  AZ_c = "${var.region}c"
}

module "s3" {
  source              = "./modules/02_s3"
  alltag              = var.alltag

}

module "sg" {
  source = "./modules/03_sg"
  alltag = var.alltag
  vpc_id = module.vpc.vpc_id
}

module "efs" {
  source = "./modules/04_efs"
  alltag = var.alltag

  public_a_subnet_id =  module.vpc.public_a_subnet_id
  public_b_subnet_id =  module.vpc.public_b_subnet_id
  public_c_subnet_id =  module.vpc.public_c_subnet_id
  private_a_subnet_id =  module.vpc.private_a_subnet_id
  private_b_subnet_id =  module.vpc.private_b_subnet_id
  private_c_subnet_id =  module.vpc.private_c_subnet_id

  sg_id = module.sg.sg_id
}

module "ec2" {
  source = "./modules/05_ec2"
  alltag = var.alltag

  depends_on = [module.efs]

  aws_bastion_size = var.aws_bastion_size
  aws_jenkins_size = var.aws_jenkins_size
  aws_master_num = var.aws_master_num
  aws_master_size = var.aws_master_size
  aws_worker_num = var.aws_worker_num
  aws_worker_size = var.aws_worker_size
  
  aws_ec2_ami = var.aws_ec2_ami
  aws_ec2_ami_jenkins = var.aws_ec2_ami_jenkins
  sg_id = module.sg.sg_id
  
  efs_dns_name = module.efs.efs_dns_name

  # a_mount = var.aws_efs_mount_target.a_mount.id
  # b_mount = var.aws_efs_mount_target.b_mount.id
  # c_mount = var.aws_efs_mount_target.c_mount.id

  public_a_subnet_id =  module.vpc.public_a_subnet_id
  public_b_subnet_id =  module.vpc.public_b_subnet_id
  public_c_subnet_id =  module.vpc.public_c_subnet_id
  private_a_subnet_id =  module.vpc.private_a_subnet_id
  private_b_subnet_id =  module.vpc.private_b_subnet_id
  private_c_subnet_id =  module.vpc.private_c_subnet_id

  AZ_a = "${var.region}a"
  AZ_b = "${var.region}b"
  AZ_c = "${var.region}c"
}

module "auto_scaling" {
  source = "./modules/06_auto_scaling"
  alltag = var.alltag
  aws_bastion_size = var.aws_master_size
  aws_ec2_ami = var.aws_ec2_ami
  sg_id = module.sg.sg_id
  private_a_subnet_id =  module.vpc.private_a_subnet_id
  private_b_subnet_id =  module.vpc.private_b_subnet_id
  private_c_subnet_id =  module.vpc.private_c_subnet_id
}



# #backend "s3"는 사용할 backend가 s3임을 의미한다.
# # --> terraform apply 후에 주석 해제하고 init 해주면 bucket에 .tfstate파일이 업데이트 된다.

# terraform {
#  backend "s3" {
#    bucket = "octopus-dream-terraform"
#    key = "terraform/terraform.tfstate"

#    encrypt = true
#    dynamodb_table = "TerraformStateLock"
#  }
# }

# #bucket : 사용할 S3 버킷명
# #key : 테라폼 state 파일을 기록할 S3 버킷 내의 파일 경로
# #region : S3 버킷이 있는 지역
# #encrypt : 테라폼 state 파일 암호화 여부
# #dynamodb_table : 사용할 DynamoDB table명