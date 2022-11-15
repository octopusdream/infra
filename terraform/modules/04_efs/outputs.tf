output "a_mount" {
   value = aws_efs_mount_target.a_mount.id
}
output "b_mount" {
   value = aws_efs_mount_target.b_mount.id
}
output "c_mount" {
   value = aws_efs_mount_target.c_mount.id
}

output "efs_dns_name" {
   value = aws_efs_file_system.efs.dns_name
}