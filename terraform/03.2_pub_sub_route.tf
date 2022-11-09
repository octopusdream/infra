# public subnet & internet Gateway의 정보가 포함된 routing table id 연결
resource "aws_route_table_association" "kakao_pub_a" {
    subnet_id = aws_subnet.kakao_pub_a.id
    route_table_id = aws_route_table.kakao_pub_rt.id
}

resource "aws_route_table_association" "kakao_pub_b" {
    subnet_id = aws_subnet.kakao_pub_b.id
    route_table_id = aws_route_table.kakao_pub_rt.id
}

resource "aws_route_table_association" "kakao_pub_c" {
    subnet_id = aws_subnet.kakao_pub_c.id
    route_table_id = aws_route_table.kakao_pub_rt.id
}