# NAT 게이트웨이 생성
resource "aws_nat_gateway" "kakao_ngw_pria" {
  allocation_id = aws_eip.kakao_ngw_puba_ip.id #EIP 연결
  subnet_id     = aws_subnet.kakao_pub_a.id #NAT가 사용될 서브넷 지정

  tags = {
    Name = "kakao-NAT-S"
  }
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}

resource "aws_nat_gateway" "kakao_ngw_prib" {
  allocation_id = aws_eip.kakao_ngw_pubb_ip.id #EIP 연결
  subnet_id     = aws_subnet.kakao_pub_b.id #NAT가 사용될 서브넷 지정

  tags = {
    Name = "kakao-NAT-b"
  }
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}

resource "aws_nat_gateway" "kakao_ngw_pric" {
  allocation_id = aws_eip.kakao_ngw_pubc_ip.id #EIP 연결
  subnet_id     = aws_subnet.kakao_pub_c.id #NAT가 사용될 서브넷 지정

  tags = {
    Name = "kakao-NAT-c"
  }
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}