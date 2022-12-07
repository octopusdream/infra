output "worker_profile" {
  value = aws_iam_instance_profile.worker_profile_seoul.name
}
output "master_profile" {
  value = aws_iam_instance_profile.master_profile_seoul.name
}

output "worker1_ip" {
  value = aws_instance.worker1[0].private_ip
}
output "worker2_ip" {
  value = aws_instance.worker1[1].private_ip
}
output "worker3_ip" {
  value = aws_instance.worker2[0].private_ip
}
output "worker4_ip" {
  value = aws_instance.worker2[1].private_ip
}
output "worker5_ip" {
  value = aws_instance.worker3[0].private_ip
}
output "worker6_ip" {
  value = aws_instance.worker3[1].private_ip
}


output "worker1_id" {
  value = aws_instance.worker1[0].id
}
output "worker2_id" {
  value = aws_instance.worker1[0].id
}
output "worker3_id" {
  value = aws_instance.worker2[0].id
}
output "worker4_id" {
  value = aws_instance.worker2[1].id
}
output "worker5_id" {
  value = aws_instance.worker3[0].id
}
output "worker6_id" {
  value = aws_instance.worker3[1].id
}
output "jenkins_id" {
  value = aws_instance.jenkins.id
}