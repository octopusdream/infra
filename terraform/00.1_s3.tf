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

resource "aws_dynamodb_table" "terraform_state_lock" {
 name= "TerraformStateLock"
 hash_key = "LockID"
 billing_mode = "PAY_PER_REQUEST"

 attribute{
  name = "LockID"
  type = "S"
 }
}

# backend "s3"는 사용할 backend가 s3임을 의미한다.
# --> terraform apply 후에 주석 해제하고 init 해주면 bucket에 .tfstate파일이 업데이트 된다.
#terraform {
# backend "s3" {
#  bucket = "kakao-terraform"
#  key = "terraform/terraform.tfstate"
#  region = "ap-northeast-2"
#  encrypt = true
#  dynamodb_table = "TerraformStateLock"
#  }
#}

#bucket : 사용할 S3 버킷명
#key : 테라폼 state 파일을 기록할 S3 버킷 내의 파일 경로
#region : S3 버킷이 있는 지역
#encrypt : 테라폼 state 파일 암호화 여부
#dynamodb_table : 사용할 DynamoDB table명