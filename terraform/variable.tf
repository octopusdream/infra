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

##################cidr_block#################
# vpc cidr_block
variable "aws_vpc_cidr_block" {
    description = "cidr block for vpc"
}

# pub_subnet cidr_block
variable "aws_puba_subnet_cidr_block" {
    description = "cidr block for pub subnet 0"
}

variable "aws_pubb_subnet_cidr_block" {
    description = "cidr block for pub subnet 1"
}

variable "aws_pubc_subnet_cidr_block" {
    description = "cidr block for pub subnet 2"
}
# pri_subnet cidr_block
variable "aws_pria_subnet_cidr_block" {
    description = "cidr block for pri subnet 3"
}

variable "aws_prib_subnet_cidr_block" {
    description = "cidr block for pri subnet 4"
}

variable "aws_pric_subnet_cidr_block" {
    description = "cidr block for pri subnet 5"
  
}


################## region #######################

# region
variable "aws_region" {
    description = "region"  
}
################### zone ######################
# korea - zone
variable "aws_availability_zone_a" {
    description = "availability_zone_a"
}

variable "aws_availability_zone_b" {
    description = "availability_zone_b"
}

variable "aws_availability_zone_c" {
    description = "availability_zone_c"
}


##########3
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