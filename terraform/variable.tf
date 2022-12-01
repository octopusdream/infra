################# company name ################
variable "alltag" {
  description = "Company name을 입력하세요"
  default     = "kakao"
}

################## region #######################
# region
variable "region" {
  description = "region"  
  default     = "ap-northeast-2"
}


################## cidr_block #############
variable "vpc_cidr_block" {
  description = "Vpc Cidr Block : x.x.x.x/x를 입력하세요"
  //default     = "10.0.0.0/16"
}

# # subnet cidr_block
variable "public_subnet_a_cidr_block" {}
variable "public_subnet_b_cidr_block" {}
variable "public_subnet_c_cidr_block" {}
variable "private_subnet_a_cidr_block" {}
variable "private_subnet_b_cidr_block" {}
variable "private_subnet_c_cidr_block" {}
  
# ##########
variable "aws_ec2_ami" {}
variable "aws_ec2_ami_jenkins" {}

variable "aws_bastion_size" {
  description = "EC2 Instance Size of Bastion Host"
}

variable "aws_bastion_num" {
  description = "EC2 Instance num of Bastion Host"
}

variable "aws_master_size" {
  description = "EC2 Instance Size of Master Host"
}

variable "aws_master_num" {
  description = "EC2 Instance num of Master Host"
}

variable "aws_worker_size" {
  description = "EC2 Instance Size of Worker Host"
}

variable "aws_worker_num" {
  description = "EC2 Instance num of Worker Host"
}

variable "aws_jenkins_size" {
  description = "EC2 Instance Size of jenkins Host"
}

# variable "a_mount" {}
# variable "b_mount" {}
# variable "c_mount" {}