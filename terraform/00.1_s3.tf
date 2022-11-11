
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

    logging {
      target_bucket = "${aws_s3_bucket.logs.id}"
      target_prefix = "log/"
    }
    
   #실수로 인한 삭제 방지
   #lifecycle {
   #  prevent_destroy = false
   #}
}



// 로그 저장용 버킷
resource "aws_s3_bucket" "logs" {
  bucket = "kakao.logs"
  acl    = "log-delivery-write"
}




#backend "s3"는 사용할 backend가 s3임을 의미한다.
# --> terraform apply 후에 주석 해제하고 init 해주면 bucket에 .tfstate파일이 업데이트 된다.

#terraform {
#  backend "s3" {
#    bucket = "kakao-terraform"
#    key = "terraform/terraform.tfstate"
#    region = "ap-northeast-2"
#    encrypt = true
#    dynamodb_table = "TerraformStateLock"
#  }
#}

#bucket : 사용할 S3 버킷명
#key : 테라폼 state 파일을 기록할 S3 버킷 내의 파일 경로
#region : S3 버킷이 있는 지역
#encrypt : 테라폼 state 파일 암호화 여부
#dynamodb_table : 사용할 DynamoDB table명