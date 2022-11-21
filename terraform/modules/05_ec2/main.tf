resource "aws_instance" "master1" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_a_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_a
  associate_public_ip_address = false
  source_dest_check = false
 
  tags = {
    Name = "${var.alltag}-master-a"
  }
  depends_on = [
    aws_instance.worker1[0],
    aws_instance.worker2[0],
    aws_instance.worker3[0],
    aws_instance.worker1[1],
    aws_instance.worker2[1],
    aws_instance.worker3[1],
    aws_instance.master2,
    aws_instance.master3
  ]
  user_data = "${data.template_file.master.rendered}"
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
  source_dest_check = false
 
  tags = {
    Name = "${var.alltag}-worker-a-${count.index + 1}"
  }
  user_data = "${data.template_file.worker.rendered}"
}

resource "aws_instance" "master2" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_b_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_b
  associate_public_ip_address = false
  source_dest_check = false

  tags = {
    Name = "${var.alltag}-master-b"
  }
  user_data = "${data.template_file.master_2.rendered}"
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
  source_dest_check = false
 
  tags = {
    Name = "${var.alltag}-worker-b-${count.index + 1}"
  }

  user_data = "${data.template_file.worker.rendered}"
}

resource "aws_instance" "master3" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_master_size
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_c_subnet_id
  key_name = "kakaokey"
  availability_zone       = var.AZ_c
  associate_public_ip_address = false
  source_dest_check = false
 
  tags = {
    Name = "${var.alltag}-master-c"
  }
  depends_on = [
    aws_instance.worker1,
    aws_instance.worker2,
    aws_instance.worker3
  ]
  user_data = "${data.template_file.master_2.rendered}"
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
  source_dest_check = false
 
  tags = {
    Name = "${var.alltag}-worker-c-${count.index + 1}"
  }

  user_data = "${data.template_file.worker.rendered}"
}

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
  user_data = "${data.template_file.user_data.rendered}"
}

resource "aws_instance" "jenkins" {
  ami = var.aws_ec2_ami_jenkins
  instance_type = var.aws_jenkins_size
  key_name = "kakaokey"
  vpc_security_group_ids = [var.sg_id]
  subnet_id = var.private_a_subnet_id
  availability_zone       = var.AZ_a
 
  tags = {
    Name = "${var.alltag}-jenkins"
  }
}

data "template_file" "user_data" {
  template = "${file("./templates/bastion.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
    jenkins_ip = aws_instance.jenkins.private_ip
    master1_ip = aws_instance.master1.private_ip
    master2_ip = aws_instance.master2.private_ip
    master3_ip = aws_instance.master3.private_ip
    worker1_ip = aws_instance.worker1[0].private_ip
    worker2_ip = aws_instance.worker1[1].private_ip
    worker3_ip = aws_instance.worker2[0].private_ip
    worker4_ip = aws_instance.worker2[1].private_ip
    worker5_ip = aws_instance.worker3[0].private_ip
    worker6_ip = aws_instance.worker3[1].private_ip
  }
}

data "template_file" "master" {
  template = "${file("./templates/master.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
    master2_ip = aws_instance.master2.private_ip
    master3_ip = aws_instance.master3.private_ip
    worker1_ip = aws_instance.worker1[0].private_ip
    worker2_ip = aws_instance.worker1[1].private_ip
    worker3_ip = aws_instance.worker2[0].private_ip
    worker4_ip = aws_instance.worker2[1].private_ip
    worker5_ip = aws_instance.worker3[0].private_ip
    worker6_ip = aws_instance.worker3[1].private_ip
  }
}


data "template_file" "master_2" {
  template = "${file("./templates/master_2.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
    worker1_ip = aws_instance.worker1[0].private_ip
    worker2_ip = aws_instance.worker1[1].private_ip
    worker3_ip = aws_instance.worker2[0].private_ip
    worker4_ip = aws_instance.worker2[1].private_ip
    worker5_ip = aws_instance.worker3[0].private_ip
    worker6_ip = aws_instance.worker3[1].private_ip
  }
}

data "template_file" "worker" {
  template = "${file("./templates/worker.tpl")}"

  vars = {
    efs_dns_name = var.efs_dns_name
  }
}
