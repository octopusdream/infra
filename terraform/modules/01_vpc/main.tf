# vpc 생성
resource "aws_vpc" "vpc" {
    cidr_block              = var.vpc_cidr_block // IPv4 CIDR Block
    instance_tenancy        = "default"
    enable_dns_hostnames    = true  // VPC에서 DNS 호스트 이름을 활성화
    enable_dns_support      = true // VPC에서 DNS 지원을 활성화
    tags = {                   // vpc name 지정
        Name                = "${var.alltag}-vpc"
    }
}

# vpc의 외부 통신을 가능하게 하기 위한 internet gateway 생성 및 vpc 연결
resource "aws_internet_gateway" "igw" {
    vpc_id                  = aws_vpc.vpc.id
    tags = {
        "Name"              = "${var.alltag}-igw"
    }
}

# # 가용 영역 a의 pubilc subnet 생성
resource "aws_subnet" "pub_a" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.public_subnet_a_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone       = var.AZ_a
 
    tags = {
        "Name"                 = "${var.alltag}-pub-a"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}



# 가용 영역 b의 pubilc subnet 생성
resource "aws_subnet" "pub_b" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.public_subnet_b_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone       = var.AZ_b 

    tags = {
        "Name"              = "${var.alltag}-pub-b"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}

# 가용 영역 c의 pubilc subnet 생성
resource "aws_subnet" "pub_c" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.public_subnet_c_cidr_block
    map_public_ip_on_launch = true #퍼블릭 IP 자동 부여 설정
    availability_zone       = var.AZ_c

    tags = {
        "Name"              = "${var.alltag}-pub-c"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}

# 가용 영역 a의 private subnet 생성
resource "aws_subnet" "pri_a" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.private_subnet_a_cidr_block
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정
    availability_zone       = var.AZ_a

    tags = {
        "Name"              = "${var.alltag}-pri-a"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}

# 가용 영역 b의 private subnet 생성
resource "aws_subnet" "pri_b" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.private_subnet_b_cidr_block
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정
    availability_zone       = var.AZ_b

    tags = {
        "Name"              = "${var.alltag}-pri-b"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}

# 가용 영역 c의 private subnet 생성
resource "aws_subnet" "pri_c" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = var.private_subnet_c_cidr_block
    map_public_ip_on_launch = false #퍼블릭 IP 자동 부여 설정 
    availability_zone       = var.AZ_c

    tags = {
        "Name"              = "${var.alltag}-pri-c"
        "kubernetes.io/role/elb" = 1,
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_vpc.vpc]
}


# public routing_table 생성
resource "aws_route_table" "pub_rt" {
    vpc_id                  = aws_vpc.vpc.id
    route {
        cidr_block          = "0.0.0.0/0"
        gateway_id          = aws_internet_gateway.igw.id
    }

    tags = {
        "Name"              = "${var.alltag}-pub-rt"
        "kubernetes.io/cluster/jordy" = "owned|shared"
    }
    depends_on              = [aws_internet_gateway.igw]
}

# public subnet & internet Gateway의 정보가 포함된 routing table id 연결
resource "aws_route_table_association" "pub_a" {
    subnet_id               = aws_subnet.pub_a.id
    route_table_id          = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_b" {
    subnet_id               = aws_subnet.pub_b.id
    route_table_id          = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_c" {
    subnet_id               = aws_subnet.pub_c.id
    route_table_id          = aws_route_table.pub_rt.id
}
###############################

###############################
# NAT 게이트웨이가 사용할 Elastic IP생성
resource "aws_eip" "ngw_puba_ip" {
    vpc                     = true  #생성 범위 지정
    tags = {
        Name                = "${var.alltag}-ngw-puba-eip"
    }
    depends_on              = [aws_internet_gateway.igw]
}

resource "aws_eip" "ngw_pubb_ip" {
    vpc                     = true  #생성 범위 지정
    tags = {
        Name                = "${var.alltag}-ngw-pubb-eip"
    }
    depends_on              = [aws_internet_gateway.igw]
}

resource "aws_eip" "ngw_pubc_ip" {
    vpc                     = true  #생성 범위 지정
    tags = {
        Name                = "${var.alltag}-ngw-pubc-eip"
    }
    depends_on              = [aws_internet_gateway.igw]
}

# # eip 생성 후 ec2 연결
# resource "aws_eip" "bastion" {
#     instance                = aws_instance.bastion.id
#     vpc                     = true
#     tags = {
#         Name                = "${var.alltag}-bastion-eip"
#     }
#     depends_on              = [aws_instance.bastion]
# }

#################################
# NAT 게이트웨이 생성
resource "aws_nat_gateway" "ngw_pria" {
    allocation_id            = aws_eip.ngw_puba_ip.id #EIP 연결
    subnet_id                = aws_subnet.pub_a.id #NAT가 사용될 서브넷 지정
    tags = {
        Name                 = "${var.alltag}-NAT-a"
    }
    # depends_on               = [aws_instance.bastion]
}

resource "aws_nat_gateway" "ngw_prib" {
    allocation_id            = aws_eip.ngw_pubb_ip.id #EIP 연결
    subnet_id                = aws_subnet.pub_b.id #NAT가 사용될 서브넷 지정

    tags = {
      Name                   = "${var.alltag}--NAT-b"
    }
    depends_on               = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw_pric" {
    allocation_id            = aws_eip.ngw_pubc_ip.id #EIP 연결
    subnet_id                = aws_subnet.pub_c.id #NAT가 사용될 서브넷 지정

    tags = {
        Name                 = "${var.alltag}-NAT-c"
        }
    depends_on               = [aws_internet_gateway.igw]
}

# private routing_table 생성
resource "aws_route_table" "pria_rt" {
    vpc_id                   = aws_vpc.vpc.id
    route {
        cidr_block           = "0.0.0.0/0"
        gateway_id           = aws_nat_gateway.ngw_pria.id
    }

    tags = {
        "kubernetes.io/cluster/jordy" = "owned|shared"
        "Name"               = "${var.alltag}-pria-rt"
    }
}

resource "aws_route_table" "prib_rt" {
    vpc_id                   = aws_vpc.vpc.id
    route {
        cidr_block           = "0.0.0.0/0"
        gateway_id           = aws_nat_gateway.ngw_prib.id
    }

    tags = {
        "kubernetes.io/cluster/jordy" = "owned|shared"
        "Name"               = "${var.alltag}-prib-rt"
    }
}

resource "aws_route_table" "pric_rt" {
    vpc_id                   = aws_vpc.vpc.id
    route {
        cidr_block           = "0.0.0.0/0"
        gateway_id           = aws_nat_gateway.ngw_pric.id
    }

    tags = {
        "kubernetes.io/cluster/jordy" = "owned|shared"
        "Name"               = "${var.alltag}-pric-rt"
    }
}

# pubvate subnet & not Gateway의 정보가 포함된 routing table id 연결
resource "aws_route_table_association" "pri_a" {
    subnet_id = aws_subnet.pri_a.id
    route_table_id = aws_route_table.pria_rt.id
}

resource "aws_route_table_association" "pri_b" {
    subnet_id = aws_subnet.pri_b.id
    route_table_id = aws_route_table.prib_rt.id
}

resource "aws_route_table_association" "pri_c" {
    subnet_id = aws_subnet.pri_c.id
    route_table_id = aws_route_table.pric_rt.id
}

####################
# s3 endpoint
resource "aws_vpc_endpoint" "s3" {
    vpc_id                   = aws_vpc.vpc.id
    service_name = "com.amazonaws.${var.region}.s3"

    tags = {
        "Name"               = "${var.alltag}-endpoint-s3"
    }
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_s3_a" {
  route_table_id = "${aws_route_table.pria_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_s3_b" {
  route_table_id = "${aws_route_table.prib_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_s3_c" {
  route_table_id = "${aws_route_table.pric_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}


# dynamodb endpoint
resource "aws_vpc_endpoint" "dynamodb" {
    vpc_id                   = aws_vpc.vpc.id
    service_name = "com.amazonaws.${var.region}.dynamodb"

    tags = {
        "Name"               = "${var.alltag}-endpoint-dynamodb"
    }
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_dynamodb_a" {
  route_table_id = "${aws_route_table.pria_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_dynamodb_b" {
  route_table_id = "${aws_route_table.prib_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_dynamodb_c" {
  route_table_id = "${aws_route_table.pric_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}