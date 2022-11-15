resource "aws_dynamodb_table" "terraform_state_lock" {
 name= "TerraformStateLock"
 hash_key = "LockID"
 billing_mode = "PAY_PER_REQUEST"

 attribute{
  name = "LockID"
  type = "S"
 }
}
# name hash_key attribute는 필수로 작성
# name은 데이터가 저장되는 테이블 이름으로 각 계정의 지역별로 고유한 값이여야 한다.
# hash_key는 테이블의 각 항목을 나타내는 고유 식별자이다.
# attribute는 잠금을 위한 속성을 나타낸다. type은 3가지로 "S"(String), "N"(Number), "B"(Binary)가 있다.


resource "aws_s3_bucket" "state" {
    bucket = "octopus-dream-terraform"
    force_destroy = true # 강제 삭제
    # 상태파일의 버전 관리 활성화 : 코드 이력 관리
    versioning {
      enabled = true
    }
    tags = {
      "Name" = "octopus-dream-terraform"
    }
    logging {
      target_bucket = "${aws_s3_bucket.logs.id}"
      target_prefix = "log/"
    }
    
    # 실수로 인한 삭제 방지
    # lifecycle {
    #   prevent_destroy = false
    # }
}

// 로그 저장용 버킷
resource "aws_s3_bucket" "logs" {
  bucket = "terraform.logs"
  acl    = "log-delivery-write"
}



