# company name
output "company" {
  value = "${var.alltag}"
}

output "aws_region" {
  value = "${var.region}"
}

output "public_a_subnet_id" {
  value = module.vpc.public_a_subnet_id
}
output "public_b_subnet_id" {
  value = module.vpc.public_b_subnet_id
}
output "public_c_subnet_id" {
  value = module.vpc.public_c_subnet_id
}
output "private_a_subnet_id" {
  value = module.vpc.private_a_subnet_id
}
output "private_b_subnet_id" {
  value = module.vpc.private_b_subnet_id
}
output "private_c_subnet_id" {
  value = module.vpc.private_c_subnet_id
}
