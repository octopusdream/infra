##### master #####
# Luanch Configuration 설정
resource "aws_launch_configuration" "master_launch" {
  image_id = var.aws_ec2_ami
  instance_type = var.aws_master_size
  key_name = "kakaokey"
  security_groups = [var.sg_id]

  iam_instance_profile = var.master_profile
  ## ASG에서 시작 구성을 사용할때 필요한 옵션: 최신 리소스를 선 생성 후 기존 리소스를 삭제
  lifecycle	{
		create_before_destroy	=	true
  }
  user_data = "${data.template_file.re_master.rendered}"
}

# # AWS AutoScaling Group 생성
# resource "aws_autoscaling_group" "master_atg1" {
#   launch_configuration = aws_launch_configuration.master_launch.name
#   vpc_zone_identifier = ["${var.private_a_subnet_id}"]
#   min_size = 0
#   max_size = 1
  
#   tags = concat(
#     [
#       {
#         "key" = "Name"
#         "value" = "terraform-${var.alltag}-master-asg"
#         "propagate_at_launch" = true
#       },
#       {
#         "key"                 = "kubernetes.io/cluster/jordy"
#         "value"               = "owned|shared"
#         "propagate_at_launch" = true
#       },
#     ]
#   )
# }

# resource "aws_autoscaling_group" "master_atg2" {
#   launch_configuration = aws_launch_configuration.master_launch.name
#   vpc_zone_identifier = ["${var.private_b_subnet_id}"]
#   min_size = 0
#   max_size = 1
  
#   tags = concat(
#     [
#       {
#         "key" = "Name"
#         "value" = "terraform-${var.alltag}-master-asg"
#         "propagate_at_launch" = true
#       },
#       {
#         "key"                 = "kubernetes.io/cluster/jordy"
#         "value"               = "owned|shared"
#         "propagate_at_launch" = true
#       },
#     ]
#   )
# }

# resource "aws_autoscaling_group" "master_atg3" {
#   launch_configuration = aws_launch_configuration.master_launch.name
#   vpc_zone_identifier = ["${var.private_c_subnet_id}"]
#   min_size = 0
#   max_size = 1
  
#   tags = concat(
#     [
#       {
#         "key" = "Name"
#         "value" = "terraform-${var.alltag}-master-asg"
#         "propagate_at_launch" = true
#       },
#       {
#         "key"                 = "kubernetes.io/cluster/jordy"
#         "value"               = "owned|shared"
#         "propagate_at_launch" = true
#       },
#     ]
#   )
# }

data "template_file" "re_master" {
  template = "${file("./templates/re_master.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
    worker1_ip = var.worker1_ip
    worker2_ip = var.worker2_ip
    worker3_ip = var.worker3_ip
    worker4_ip = var.worker4_ip
    worker5_ip = var.worker5_ip
    worker6_ip = var.worker6_ip
  }
}

##### worker #####
# Luanch Configuration 설정
resource "aws_launch_configuration" "worker_launch" {
  image_id = var.aws_ec2_ami
  instance_type = var.aws_worker_size
  key_name = "kakaokey"
  security_groups = [var.sg_id]

  iam_instance_profile = var.worker_profile
  ## ASG에서 시작 구성을 사용할때 필요한 옵션: 최신 리소스를 선 생성 후 기존 리소스를 삭제
  lifecycle	{
		create_before_destroy	=	true
  }
  user_data = "${data.template_file.worker_auto_scaling.rendered}"
}

resource "aws_autoscaling_group" "worker_atg" {
  launch_configuration = aws_launch_configuration.worker_launch.name
  vpc_zone_identifier = ["${var.private_a_subnet_id}"]
  min_size = 0
  max_size = 12
  
  tags = concat(
    [
      {
        "key" = "Name"
        "value" = "terraform-${var.alltag}-werker-asg"
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



data "template_file" "worker_auto_scaling" {
  template = "${file("./templates/worker_auto_scaling.tpl")}"

  vars = {
    key_pem = file("./templates/key.pem")
  }
}
