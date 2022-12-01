# # # company name
variable "alltag" {}

# # korea - zone(a)
variable "AZ_a" {}
variable "AZ_b" {}
variable "AZ_c" {}

variable "aws_jenkins_size" {}
variable "aws_bastion_size" {}
variable "aws_master_size" {}
variable "aws_master_num" {}
variable "aws_worker_size" {}
variable "aws_worker_num" {}

variable "public_a_subnet_id" {}
variable "public_b_subnet_id" {}    
variable "public_c_subnet_id" {}
variable "private_a_subnet_id" {} 
variable "private_b_subnet_id" {}    
variable "private_c_subnet_id" {} 

variable "aws_ec2_ami" {}
variable "aws_ec2_ami_jenkins" {}

variable "efs_dns_name" {}

# variable "a_mount" {}
# variable "b_mount" {}
# variable "c_mount" {}

variable "sg_id" {}

variable "master_nlb_dns_name" {}

variable "bastion_volume_size" {}