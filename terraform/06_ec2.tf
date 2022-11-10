# eip 생성 후 ec2 연결
resource "aws_eip" "bastion1" {
  instance = aws_instance.bastion1.id
  vpc      = true
  tags = {
    Name = "kakao-bastion1-eip"
  }
}


resource "aws_instance" "bastion1" {
  #count = 3
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_bastion_size
  key_name = "kakaokey"
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pub_a.id
  availability_zone = var.aws_availability_zone_a
 
  tags = {
    Name = "bastion-a"
  }
}

resource "aws_instance" "master1" {
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_master_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_a.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_a
  associate_public_ip_address = false
 
  tags = {
    Name = "master-a"
  }
}

resource "aws_instance" "worker1" {
  ami = "ami-0e9bfdb247cc8de84"
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_a.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_a
  associate_public_ip_address = false
 
  tags = {
    Name = "worker-a-${count.index + 1}"
  }
}

# eip 생성 후 ec2 연결
resource "aws_eip" "bastion2" {
  instance = aws_instance.bastion2.id
  vpc      = true
  tags = {
    Name = "kakao-bastion2-eip"
  }
}


resource "aws_instance" "bastion2" {
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_bastion_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pub_b.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_b
 
  tags = {
    Name = "bastion-b"
  }
}

resource "aws_instance" "master2" {
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_master_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_b.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_b
  associate_public_ip_address = false
 
  tags = {
    Name = "master-b"
  }
}

resource "aws_instance" "worker2" {
  ami = "ami-0e9bfdb247cc8de84"
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_b.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_b
  associate_public_ip_address = false
 
  tags = {
    Name = "worker-b-${count.index + 1}"
  }
}

# eip 생성 후 ec2 연결
resource "aws_eip" "bastion3" {
  instance = aws_instance.bastion3.id
  vpc      = true
  tags = {
    Name = "kakao-bastion3-eip"
  }
}


resource "aws_instance" "bastion3" {
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_bastion_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pub_c.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_c
  
 
  tags = {
    Name = "bastion-c"
  }
}

resource "aws_instance" "master3" {
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_master_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_c.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_c
  associate_public_ip_address = false
 
  tags = {
    Name = "master-c"
  }
}

resource "aws_instance" "worker3" {
  ami = "ami-0e9bfdb247cc8de84"
  count = var.aws_worker_num
  instance_type = var.aws_worker_size
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pri_c.id
  key_name = "kakaokey"
  availability_zone = var.aws_availability_zone_c
  associate_public_ip_address = false
 
  tags = {
    Name = "worker-c-${count.index + 1}"
  }
}