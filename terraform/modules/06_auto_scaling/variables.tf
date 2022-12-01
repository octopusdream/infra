# company name
variable "alltag" {}

variable "aws_worker_size" {}
variable "aws_ec2_ami" {}

variable "private_a_subnet_id" {} 
variable "private_b_subnet_id" {}    
variable "private_c_subnet_id" {} 

variable "sg_id" {}
variable "efs_dns_name" {}

variable "master1_ip" {}
variable "master2_ip" {}
variable "master3_ip" {}

variable "worker_profile" {}
variable "master_nlb_dns_name" {}
