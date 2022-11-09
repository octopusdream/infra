# vpc의 외부 통신을 가능하게 하기 위한 internet gateway 생성 및 vpc 연결
resource "aws_internet_gateway" "kakao_igw" {
  vpc_id = aws_vpc.kakao_vpc.id

  tags = {
    "Name" = "kakao-igw"
  }
}


