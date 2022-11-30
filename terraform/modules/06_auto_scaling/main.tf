# Luanch Configuration 설정
resource "aws_launch_configuration" "launch" {
  image_id = var.aws_ec2_ami
  instance_type = var.aws_worker_size
  key_name = "kakaokey"
  security_groups = [var.sg_id]

  iam_instance_profile = var.worker_profile
  ## ASG에서 시작 구성을 사용할때 필요한 옵션: 최신 리소스를 선 생성 후 기존 리소스를 삭제
  lifecycle	{
		create_before_destroy	=	true
  }
  user_data = "${data.template_file.auto_scaling.rendered}"
}


# AWS AutoScaling Group 생성
resource "aws_autoscaling_group" "atg" {
  launch_configuration = aws_launch_configuration.launch.name
  vpc_zone_identifier = ["${var.private_a_subnet_id}","${var.private_b_subnet_id}","${var.private_c_subnet_id}"]
  min_size = 0
  max_size = 12
  
  tags = concat(
    [
      {
        "key" = "Name"
        "value" = "terraform-${var.alltag}-asg"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "kubernetes.io/cluster/jordy"
        "value"               = "owned|shared"
        "propagate_at_launch" = true
      },
    ]
  )
}

data "template_file" "auto_scaling" {
  template = "${file("./templates/auto_scaling.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
    efs_dns_name = var.efs_dns_name
    master1_ip = var.master1_ip
  }
}