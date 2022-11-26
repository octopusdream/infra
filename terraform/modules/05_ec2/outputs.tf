output "master1_ip" {
  value = aws_instance.master1.private_ip
}

output "worker_profile" {
  value = aws_iam_instance_profile.worker_profile.name
}

output "master1_id" {
  value = aws_instance.master1.id
}
output "master2_id" {
  value = aws_instance.master1.id
}
output "master3_id" {
  value = aws_instance.master1.id
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