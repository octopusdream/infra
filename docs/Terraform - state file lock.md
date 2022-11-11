# Terraform Backend 활용하기

## 1. 테라폼 상태(Terraform state)란?
- Terraform Backend 활용하기 앞서 terraform state 관리에 대해 설명 하고 넘어가겠다.
- terraform state 관리에는 대표적으로 Local state와 backend state로 나누어진다.
### Local state 란?
- terraform init & apply 와 같은 명령어를 실행하게 되면 아래와 같은 파일들이 생성됩니다. 
```
.terraform - terraform init 명령어를 실행할 때 생성된다.

.terraform.lock.hcl - 잠금 파일이며 경쟁 상태에서 생길 수 있는 문제들을 예방할 수 있다.

terraform.tfstate - terraform apply 명령어 실행 후 생성된다.
```
- 이 파일들은 local 환경에서 관리 된다.


### terraform backend 란?
- 각 terraform configuration은 작업이 수행되는 위치와 방법, 상태 스냅샷이 저장되는 위치 등을 정의하는 백엔드를 지정할 수 있다. 
- tfstate 파일에는 민감한 정보가 포함될 수 있으므로 공개된 장소에서는 관리하지 않도록 권장한다. [State: Sensitive Data | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
- AWS S3에서 tfstate 관리
[Backend Configuration - Configuration Language | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
기본적으로 로컬 스토리지에 저장을 하지만, 설정에 따라서 zure, Consul, etcd, AWS S3, Terraform Enterprise, Google Cloud Storage 등 다양한 원격 Backend 타입을 사용할 수 있다.
### Terraform Backend 사용 이유
![image](https://user-images.githubusercontent.com/72699541/201298170-5aa68b78-d893-4c97-9776-584ac437c0d3.png)
- Locking
  - 동시에 두 사람이 작업을 하는 경우에 `terraform.tfstate` 가 달라지며 충돌이 발생할 수 있다. 이는 파일의 충돌만이 아니라 인프라에도 영향을 줄 수 있다.
  - git 으로 작업하면서 pull로 내용을 가져오지 않고 작업한다면 전에 존재하던 `terraform.tfstate` 의 내용을 덮어쓰면서 충돌이 발생할 수 있다.
  - S3와 같은 원격 저장소를 사용하면 동시에 같은 state 파일에 대한 접근을 막아 의도치 않는 변경 사항을 방지할 수 있다.
- Backup
  - 로컬 저장소에 저장한다는 것은 유실할 수 있다는 가능성이 있다.
  - 그렇기 때문에 S3와 같은 원격 저장소를 사용함으로써 state 파일의 유실을 방지할 수 있다.
---
## 2. Terrform Backend 구현
- 테라폼의 상태를 저장하기 위해 S3 bucket, 동시에 같은 파일을 수정하지 못하도록 막기 위해 DynamoDB를 사용한다.
- 본 프로젝트에서 terraform backend 설정을 하기 위한 S3와 DynamoDB를 생성하는 코드를 예제로 사용하겠다.
### DynamoDB(lock 테이블)
```
# DynamoDB table 생성(terrafrom state 파일용 lock 테이블)
resource "aws_dynamodb_table" "terraform_state_lock" {
 name= "TerraformStateLock"
 hash_key = "LockID"
 billing_mode = "PAY_PER_REQUEST"

 attribute{
  name = "LockID"
  type = "S"
 }
}
```
DynamoDB 에 테이블을 만들어준다. 이 테이블은 S3 에서 tfstate 파일을 관리하면서 동시에 작업이 일어나지 않도록 하는 lock 테이블이다. lock 을 사용할지는 선택 사항이지만 원격으로 상태 파일을 관리하므로 동시에 작업하면서 인프라에 문제가 생기지 않도록 lock 테이블을 만들면 plan 이나 apply 를 할 때 먼저 lock 이 걸리고, 작업이 끝나면 lock 이 해제된다.

- dynamodb_table을 생성할 때는 name hash_key attribute는 필수로 작성해 주어야 한다
  - name은 데이터가 저장되는 테이블 이름으로 각 계정의 지역별로 고유한 값이여야 한다.
  - hash_key는 테이블의 각 항목을 나타내는 고유 식별자이다.
  - attribute는 잠금을 위한 속성을 나타낸다. type은 3가지로 "S"(String), "N"(Number), "B"(Binary)가 있다.
---

### log 버킷

로그 데이터를 저장할 S3 버킷을 생성한다. 이는 `terraform.tfstate` 용 S3 버킷에서 로깅을 켜서 누가 접근해서 작업했는지 알 수 있도록 여기에 기록을 남긴다. 

```bash
// 로그 저장용 버킷
resource "aws_s3_bucket" "logs" {
  bucket = "kr.ne.outsider.logs"
  acl    = "log-delivery-write"
}
```

-----

### acl

Amazon S3 ACL(액세스 제어 목록)을 사용하면 버킷 및 객체에 대한 액세스를 관리할 수 있다.

각 버킷과 객체에는 하위 리소스로 연결된 ACL이 있다. 액세스 권한이 부여된 AWS 계정 또는 그룹과 액세스 유형을 정의합니다. 리소스에 대한 요청이 수신되면 Amazon S3는 해당 ACL을 확인하여 요청자에게 필요한 액세스 권한이 있는지 확인합니다.

[Access control list (ACL) overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl)

• **`[acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#acl)`**- 적용할 acl 이다. 유효한 값은 **`private`**, **`public-read`**, **`public-read-write`**, **`aws-exec-read`**, **`authenticated-read`**및 **`log-delivery-write`**입니다. 기본 값은 **`private`** 이다. 

---

### Terraform state 저장용 버킷
`terrafrom.tfstate` 가 저장되는 S3 버킷을 생성한다.
```
# S3 bucket 생성(log 저장용 버킷)
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
  # 실수로 인한 삭제 방지
  # lifecycle {
  #   prevent_destroy = false
  #}
}
```
S3의 버전 관리를 키면 `terraform.tfstate` 파일을 변경할 때마다 S3가 알아서 예전 버전을 관리해주어 문제가 생겼을 때 복구할 수 있다.

```bash
# 상태파일의 버전 관리 활성화 : 코드 이력 관리
  versioning {
    enabled = true
  }
```

로깅을 활성화하고 앞에서 만든 로깅용 S3 버킷을 지정해주어 버킷의 파일을 수정할 때마다 로깅 버킷에 데이터가 남게된다.

```bash
  logging {
    target_bucket = "${aws_s3_bucket.logs.id}"
    target_prefix = "log/"
  }
```
---

### backend 추가

[Backend Type: s3 | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

앞에서 생성한 버킷을 사용할 수 있도록 backend 를 추가해준다.

```
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
```

- S3 backend 사용하기전 먼저 S3 bucket과 DynamoDB table 리소스를 apply해 주어야 하며, 이후 S3 backend에는 bucket,key,region 옵션은 반드시 명시해야 하며, state 저장소가 변경되는 것이기 때문에 terraform init을 해주어야 한다.
- init을 하게 되면 .tfstate 파일을 backend로 copy할건지 물어보게 되고 yes를 하면 된다.
- 최종적으로 로컬에 있는 .tfstate 파일은 이제 필요하지 않으며, 설정한 값(S3 bucket)으로 terraform.tfstate 파일이 만들어지게 된다.


하나의 버킷에 여러 `terraform.tfstate` 를 관리하기 위해서 키를 지정해 계층을 준다.

`encrypt` 를 설정해 [S3의 암호화 기능](https://docs.aws.amazon.com/ko_kr/AmazonS3/latest/dev/UsingServerSideEncryption.html)을 사용하도록 해준다. 암호화해서 저장하므로 혹시나 유출됐을 때 문제를 막을 수 있다.

-----

### terraform plan

`terraform` 키워드를 이용한 백엔드 설정이 있으면 Terraform은 `terraform.tfstate`를 로컬에서 관리하지 않고 원격에서 관리한다고 생각한다. 그래서 `terraform plan`을 실행하면 오류가 난다.

```bash
...
│ Error: Backend initialization required, please run "terraform init"
│
│ Reason: Initial configuration of the requested backend "s3"
│
│ The "backend" is the interface that Terraform uses to store state,
│ perform operations, etc. If this message is showing up, it means that the
│ Terraform configuration you're using is using a custom configuration for
│ the Terraform backend.
...
```

이는 terraform 설정을 초기화해주어야한다는 것이므로 `terraform init` 을 사용해 초기화해주면 된다. 로컬에서 `terraform.tfstate`를 관리하고 있었다면 이를 백엔드로 올리면서 초기화를 하고 이미 원격에서 관리하는 Terraform 설정을 다운 받았다면 이 설정을 초기화하는 과정이 이루어진다.

-----

### error

[Amazon S3용 엔드포인트](https://docs.aws.amazon.com/ko_kr/vpc/latest/privatelink/vpc-endpoints-s3.html)

```bash
PS C:\Users\user\Desktop\terraform> terraform init   

Initializing the backend...
Error refreshing state: BucketRegionError: incorrect region, the bucket is not in 'ap-northeast-2' 
region at endpoint '', bucket is in 'us-east-2' region
        status code: 301, request id: MM4M1WQ5XKNJATM8, host id: nsGHgzP6wU+lj4niA5/KNKj4Fbhh05l4e4GAl4EX0qqxMxHDvBpp8ubRdc9tPtZZuVA1FbWE/3c=
```

- 코드 상의 리전과 버킷이 위치한 리전이 달라서 생긴 문제 ([https://www.notion.so/tfstate-lock-d1b45cfec38c4c428391430c2720319d#cd9b7a69e9b6493ba73233f9df735238](https://www.notion.so/tfstate-lock-d1b45cfec38c4c428391430c2720319d))

- endpoint 를 설정해주고 다시



