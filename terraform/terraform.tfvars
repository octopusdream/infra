
####### cidr_block
vpc_cidr_block = "10.0.0.0/16"
public_subnet_a_cidr_block = "10.0.0.0/24"
public_subnet_b_cidr_block = "10.0.1.0/24"
public_subnet_c_cidr_block = "10.0.2.0/24"
private_subnet_a_cidr_block = "10.0.3.0/24"
private_subnet_b_cidr_block = "10.0.4.0/24"
private_subnet_c_cidr_block = "10.0.5.0/24"


######## region
# region = "ap-northeast-2"

aws_ec2_ami = "ami-08c2ee02329b72f26"
aws_ec2_ami_jenkins = "ami-0e0cbf0f03ba99ee7"

aws_bastion_size = "t3.micro"
aws_bastion_num  = 3

aws_master_size = "t3.medium"
aws_master_num  = 3

aws_worker_size = "t3.medium"
aws_worker_num  = 2

aws_jenkins_size = "t3.small"
