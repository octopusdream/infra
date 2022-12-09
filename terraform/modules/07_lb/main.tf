##### nlb #####
resource "aws_lb" "nlb" {
  name               = "nlb"
  internal           = false  # flase 외부용 LB, true 내부용
  load_balancer_type = "network"
  # security_groups = ["${var.sg_id}"]
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

  # log s3 저장
  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb.id}"
  #   prefix  = "frontend-lb"
  #   enabled = true
  # }

  tags = {
        Name = "nlb"
  }

  # lifecycle { create_before_destroy = true }
}


# target group
resource "aws_lb_target_group" "lb-tg" {
  name     = "nlb-target-group"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  # health_check {
  #   interval            = 30
  #   path                = "/ping"
  #   healthy_threshold   = 3
  #   unhealthy_threshold = 3
  # }

  tags = { Name = "nlb Target Group" }
}

resource "aws_lb_target_group_attachment" "lb-tg-attachment1" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker1_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment2" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker2_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment3" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker3_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment4" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker4_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment5" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker5_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment6" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.worker6_id}"
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb-tg-attachment7" {
  target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
  target_id        = "${var.jenkins_id}"
  port             = 80
}


# listener
resource "aws_lb_listener" "http1" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.lb-tg.arn}"
    type             = "forward"
  }
}


#### nlb #####
resource "aws_lb" "master-nlb" {
  name               = "master-nlb"
  internal           = true  # flase 외부용 LB, true 내부용
  load_balancer_type = "network"
  # security_groups = ["${var.sg_id}"]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false # true 면 삭제 방지
  
  subnet_mapping {
    subnet_id     = var.private_a_subnet_id
  }
  subnet_mapping {
    subnet_id     = var.private_b_subnet_id
  }
  subnet_mapping {
    subnet_id     = var.private_c_subnet_id
  }

  # log s3 저장
  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb.id}"
  #   prefix  = "frontend-lb"
  #   enabled = true
  # }

  tags = {
        Name = "nlb"
  }

  # lifecycle { create_before_destroy = true }
}


# target group
resource "aws_lb_target_group" "master-nlb-tg" {
  name     = "master-nlb-target-group"
  port        = 6443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = 6443
  }

  tags = { Name = "master-nlb Target Group" }
}

resource "aws_lb_target_group_attachment" "master-nlb-tg-attachment1" {
  target_group_arn = "${aws_lb_target_group.master-nlb-tg.arn}"
  target_id        = "10.0.3.100"
  port             = 6443
}

resource "aws_lb_target_group_attachment" "master-nlb-tg-attachment2" {
  target_group_arn = "${aws_lb_target_group.master-nlb-tg.arn}"
  target_id        = "10.0.4.100"
  port             = 6443
}

resource "aws_lb_target_group_attachment" "master-nlb-tg-attachment3" {
  target_group_arn = "${aws_lb_target_group.master-nlb-tg.arn}"
  target_id        = "10.0.5.100"
  port             = 6443
}

# listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.master-nlb.arn}"
  port              = "6443"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.master-nlb-tg.arn}"
    type             = "forward"
  }
}

