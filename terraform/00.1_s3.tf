resource "aws_s3_bucket" "kakao_state" {
    bucket = "kakao-terraform"
    force_destroy = true # 강제 삭제
    tags = {
      "Name" = "kakao-terraform"
    }
    # 상태파일의 버전 관리 활성화 : 코드 이력 관리
    versioning {
      enabled = true
    }
    # 실수로 인한 삭제 방지
   # lifecycle {
   #   prevent_destroy = false
   # }
}

