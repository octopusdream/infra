# public routing_table 생성
resource "aws_route_table" "kakao_pub_rt" {
    vpc_id = aws_vpc.kakao_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.kakao_igw.id
    }

    tags = {
      "Name" = "kakao-pub-rt"
    }
    depends_on = [aws_internet_gateway.kakao_igw]
}
