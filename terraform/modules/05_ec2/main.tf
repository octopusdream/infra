resource "aws_instance" "bastion" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_bastion_size
  key_name = "kakaokey"
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.public_a_subnet_id
  availability_zone       = var.AZ_a
 
  tags = {
    Name = "${var.alltag}-bastion"
  }
}

resource "aws_instance" "master1" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_a_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_a
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-master-a"
  }
}

resource "aws_instance" "worker1" {
  ami = var.aws_ec2_ami
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_a_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_a
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-worker-a-${count.index + 1}"
  }

  user_data = <<-EOF
    #!/bin/bash   
    sudo su -
    sudo mkdir /efs
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_dns_name}:/ /efs
    df -h
    touch /efs/kakao
    ls /efs
    EOF

  # depends_on = [
    # var.a_mount
  # ]
}


resource "aws_instance" "master2" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_b_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_b
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-master-b"
  }
}

resource "aws_instance" "worker2" {
  ami = var.aws_ec2_ami
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_b_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_b
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-worker-b-${count.index + 1}"
  }

  user_data = <<-EOF
    #!/bin/bash   
    sudo su -
    sudo mkdir /efs
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_dns_name}:/ /efs
    df -h
    touch /efs/kakao
    ls /efs
    EOF

  # depends_on = [
  #   var.b_mount
  # ]
}

resource "aws_instance" "master3" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_c_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_c
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-master-c"
  }
}

resource "aws_instance" "worker3" {
  ami = var.aws_ec2_ami
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_c_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_c
  associate_public_ip_address = false
 
  tags = {
    Name = "${var.alltag}-worker-c-${count.index + 1}"
  }

  user_data = <<-EOF
    #!/bin/bash   
    sudo su -
    sudo mkdir /efs
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_dns_name}:/ /efs
    df -h
    touch /efs/kakao
    ls /efs
    EOF

  # depends_on = [
  #   aws_efs_mount_target.c_mount
  #   ]
}