# pubvate subnet & not Gateway의 정보가 포함된 routing table id 연결
resource "aws_route_table_association" "kakao_pri_a" {
    subnet_id = aws_subnet.kakao_pri_a.id
    route_table_id = aws_route_table.kakao_pria_rt.id
}

resource "aws_route_table_association" "kakao_pri_b" {
    subnet_id = aws_subnet.kakao_pri_b.id
    route_table_id = aws_route_table.kakao_prib_rt.id
}

resource "aws_route_table_association" "kakao_pri_c" {
    subnet_id = aws_subnet.kakao_pri_c.id
    route_table_id = aws_route_table.kakao_pric_rt.id
}