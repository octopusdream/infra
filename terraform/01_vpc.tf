# vpc 생성
resource "aws_vpc" "kakao_vpc" {
    cidr_block = var.aws_vpc_cidr_block // IPv4 CIDR Block
    instance_tenancy = "default"
    enable_dns_hostnames = true  // VPC에서 DNS 호스트 이름을 활성화
    enable_dns_support = true // VPC에서 DNS 지원을 활성화
    
    tags = {                   // vpc name 지정
      Name = "kakao-vpc"
  }
}