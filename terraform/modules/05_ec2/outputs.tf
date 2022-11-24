output "master1_ip" {
  value = aws_instance.master1.private_ip
}

output "worker_profile" {
  value = aws_iam_instance_profile.worker_profile.name
}
