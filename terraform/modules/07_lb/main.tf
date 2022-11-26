##### alb #####
resource "aws_alb" "alb" {
  name            = "alb"
  internal        = true
  security_groups = ["${var.sg_id}"]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false # true 면 삭제 방지

  subnets         = [
    "${var.private_a_subnet_id}",
    "${var.private_b_subnet_id}",
    "${var.private_c_subnet_id}"
  ]

# log s3 저장
#   access_logs {
#     bucket  = "${aws_s3_bucket.alb.id}"
#     prefix  = "frontend-alb"
#     enabled = true
#   }

  tags = {
    Name = "ALB"
  }

#   lifecycle { create_before_destroy = true }
}


# target group
resource "aws_alb_target_group" "alb-tg" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

#   health_check {
#     interval            = 30
#     path                = "/ping"
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }

  tags = { Name = "alb Target Group" }
}

resource "aws_alb_target_group_attachment" "alb-tg-attachment1" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker1_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment2" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker2_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment3" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker3_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment4" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker4_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment5" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker5_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment6" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.worker6_id}"
  port             = 80
}
resource "aws_alb_target_group_attachment" "alb-tg-attachment7" {
  target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
  target_id        = "${var.jenkins_id}"
  port             = 80
}


# listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb-tg.arn}"
    type             = "forward"
  }
}


##### nlb #####
resource "aws_lb" "nlb" {
  name               = "nlb"
  internal           = false  # flase 외부용 LB, true 내부용
  load_balancer_type = "network"
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false # true 면 삭제 방지
  
  subnet_mapping {
    subnet_id     = var.public_a_subnet_id
    allocation_id = var.nlb_ip1_id
  }

  subnet_mapping {
    subnet_id     = var.public_b_subnet_id
    allocation_id = var.nlb_ip2_id

  }

  tags = {
        Name = "nlb"
  }
  depends_on = [aws_alb.alb]
}

# target group
resource "aws_lb_target_group" "nlb-tg" {
  name     = "nlb-target-group"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  tags = { Name = "nlb Target Group" }
}

resource "aws_lb_target_group_attachment" "nlb-tg-attachment" {
  target_group_arn = "${aws_lb_target_group.nlb-tg.arn}"
  target_id        = "${aws_alb.alb.id}"
  port             = 80
}


# listener
resource "aws_lb_listener" "http3" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nlb-tg.arn}"
    type             = "forward"
  }
}