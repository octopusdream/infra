# eip 생성 후 ec2 연결
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true
  tags = {
    Name = "kakao-bastion-eip"
  }
}
