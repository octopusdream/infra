# private routing_table 생성
resource "aws_route_table" "kakao_pria_rt" {
    vpc_id = aws_vpc.kakao_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.kakao_ngw_pria.id
    }

    tags = {
      "Name" = "kakao-pria-rt"
    }
}

resource "aws_route_table" "kakao_prib_rt" {
    vpc_id = aws_vpc.kakao_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.kakao_ngw_prib.id
    }

    tags = {
      "Name" = "kakao-prib-rt"
    }
}

resource "aws_route_table" "kakao_pric_rt" {
    vpc_id = aws_vpc.kakao_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.kakao_ngw_pric.id
    }

    tags = {
      "Name" = "kakao-pric-rt"
    }
}