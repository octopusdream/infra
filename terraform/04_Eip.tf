# NAT 게이트웨이가 사용할 Elastic IP생성
resource "aws_eip" "kakao_ngw_puba_ip" {
  vpc      = true  #생성 범위 지정
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}

resource "aws_eip" "kakao_ngw_pubb_ip" {
  vpc      = true  #생성 범위 지정
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}

resource "aws_eip" "kakao_ngw_pubc_ip" {
  vpc      = true  #생성 범위 지정
  depends_on = [
    aws_internet_gateway.kakao_igw
  ]
}

# eip 생성 후 ec2 연결
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true
  tags = {
    Name = "kakao-bastion-eip"
  }
}
