# 다른 모듈에서 사용할 vpc id
output "vpc_id" {
  value = aws_vpc.vpc.id
}


# 다른 모듈에서 사용할 igw id
output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "public_a_subnet_id" {
  value = aws_subnet.pub_a.id
}
output "public_b_subnet_id" {
  value = aws_subnet.pub_b.id
}
output "public_c_subnet_id" {
  value = aws_subnet.pub_c.id
}

output "private_a_subnet_id" {
  value = aws_subnet.pri_a.id
}
output "private_b_subnet_id" {
  value = aws_subnet.pri_b.id
}
output "private_c_subnet_id" {
  value = aws_subnet.pri_c.id
}

output "nlb_ip1_id" {
  value = aws_eip.nlb_ip1.id
}

output "nlb_ip2_id" {
  value = aws_eip.nlb_ip2.id
}