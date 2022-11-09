# 가용 영역 a의 pubilc subnet 생성
resource "aws_subnet" "kakao_pub_a" {
    vpc_id          = aws_vpc.kakao_vpc.id
    cidr_block      = var.aws_puba_subnet_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone = var.aws_availability_zone_a 
    tags = {
      "Name" = "kakao-pub-a"
    }
}

# 가용 영역 b의 pubilc subnet 생성
resource "aws_subnet" "kakao_pub_b" {
    vpc_id          = aws_vpc.kakao_vpc.id
    cidr_block      = var.aws_pubb_subnet_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone = var.aws_availability_zone_b 
    tags = {
      "Name" = "kakao-pub-b"
    }
}

# 가용 영역 c의 pubilc subnet 생성
resource "aws_subnet" "kakao_pub_c" {
    vpc_id          = aws_vpc.kakao_vpc.id
    cidr_block      = var.aws_pubc_subnet_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone = var.aws_availability_zone_c 
    tags = {
      "Name" = "kakao-pub-c"
    }
}

# 가용 영역 a의 private subnet 생성
resource "aws_subnet" "kakao_pri_a" {
    vpc_id = aws_vpc.kakao_vpc.id
    cidr_block = var.aws_pria_subnet_cidr_block 
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정
    availability_zone = var.aws_availability_zone_a
    tags = {
      "Name" = "kakao-pri-a"
    }
}

# 가용 영역 b의 private subnet 생성
resource "aws_subnet" "kakao_pri_b" {
    vpc_id = aws_vpc.kakao_vpc.id
    cidr_block = var.aws_prib_subnet_cidr_block 
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정
    availability_zone = var.aws_availability_zone_b
    tags = {
      "Name" = "kakao-pri-b"
    }
}

# 가용 영역 c의 private subnet 생성
resource "aws_subnet" "kakao_pri_c" {
    vpc_id = aws_vpc.kakao_vpc.id
    cidr_block = var.aws_pric_subnet_cidr_block
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정 
    availability_zone = var.aws_availability_zone_c
    tags = {
      "Name" = "kakao-pri-c"
    }
}