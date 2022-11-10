
resource "aws_instance" "bastion" {
  #count = 3
  ami = "ami-0e9bfdb247cc8de84"
  instance_type = var.aws_bastion_size
  key_name = "kakaokey"
  vpc_security_group_ids = [aws_security_group.kakao_http.id]
  subnet_id = aws_subnet.kakao_pub_a.id
  availability_zone = var.aws_availability_zone_a
 
  tags = {
    Name = "bastion"
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