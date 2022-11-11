# EFS 파일 시스템 생성
resource "aws_efs_file_system" "kakao_efs" {
  # 원존 클래스를 이용할 경우
  # availability_zone_name = "ap-northeast-2a"

  # 유휴 시 데이터 암호화
  encrypted = true
  # KMS에서 관리형 키를 이용하려면 kms_key_id 속성을 붙여줍니다.

  # 성능 모드: generalPurpose(범용 모드(일반 웹서비스 환경)), maxIO(최대 IO 모드)
  performance_mode = "generalPurpose"
  
  # 버스팅 처리량 모드 (일시적으로 단기간 처리량을 끌어 올림)
  throughput_mode = "bursting"

  # 프로비저닝 처리량 모드 (Bursting 보다 더 많은 처리량을 요구 할 때 )
  # throughput_mode = "provisioned"
  # provisioned_throughput_in_mibps = 100
  tags = {
    Name = "kakao-efs"
  }

  # 수명 주기 관리
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

# 표준 클래스로 EFS를 생성하더라도 탑재 대상은 모든 가용영역에 수동으로 지정해주어야 합니다. 
resource "aws_efs_mount_target" "kakao_a_mount" {
  file_system_id  = aws_efs_file_system.kakao_efs.id
  subnet_id       = aws_subnet.kakao_pub_a.id
  security_groups = [aws_security_group.kakao_http.id] 
}

resource "aws_efs_mount_target" "kakao_b_mount" {
  file_system_id  = aws_efs_file_system.kakao_efs.id
  subnet_id       = aws_subnet.kakao_pub_b.id
  security_groups = [aws_security_group.kakao_http.id] 
}

resource "aws_efs_mount_target" "kakao_c_mount" {
  file_system_id  = aws_efs_file_system.kakao_efs.id
  subnet_id       = aws_subnet.kakao_pub_c.id
  security_groups = [aws_security_group.kakao_http.id] 
}
