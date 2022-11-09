# Luanch Configuration 설정
resource "aws_launch_configuration" "kakao_launch" {
  image_id = "ami-0e9bfdb247cc8de84"
  instance_type = "t3.micro"
  key_name = "kakaokey"
  security_groups = [aws_security_group.kakao_http.id]
  ## ASG에서 시작 구성을 사용할때 필요한 옵션: 최신 리소스를 선 생성 후 기존 리소스를 삭제
  lifecycle	{
		create_before_destroy	=	true
    }
} 

# AWS AutoScaling Group 생성
resource "aws_autoscaling_group" "kakao_atg" {
  launch_configuration = aws_launch_configuration.kakao_launch.name
  vpc_zone_identifier = ["${aws_subnet.kakao_pri_a.id}","${aws_subnet.kakao_pri_b.id}","${aws_subnet.kakao_pri_c.id}"]
  min_size = 0
  max_size = 12

  tag {
    key = "Name"
    value = "terraform-kakao-asg"
    propagate_at_launch = true
  }
}