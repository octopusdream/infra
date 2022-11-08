
### tfstate

![캡처](https://user-images.githubusercontent.com/72699541/200494927-023c5d80-cc5b-49be-82a5-78b900690a62.PNG)

[State | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/state)

- 동시에 두 사람이 작업을 하는 경우에 `terraform.tfstate` 가 달라지며 충돌이 발생할 수 있다. 이는 파일의 충돌만이 아니라 인프라에도 영향을 줄 수 있다.
- git 으로 작업하면서 pull로 내용을 가져오지 않고 작업한다면 전에 존재하던 `terraform.tfstate` 의 내용을 덮어쓰면서 충돌이 발생할 수 있다.

따라서 terraform 에서는 tfstate 파일을 원격으로 관리하는 방법을 제공한다. 

[State: Remote Storage | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/state/remote)

tfstate 파일에는 민감한 정보가 포함될 수 있으므로 공개된 장소에서는 관리하지 않도록 권장한다.

[State: Sensitive Data | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/state/sensitive-data)

- AWS S3에서 tfstate 관리

[Backend Configuration - Configuration Language | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)

현재 원격 백엔드로는 Azure, Consul, etcd, AWS S3, Terraform Enterprise, Google Cloud Storage를 지원하고 있다.

### lock 테이블

S3 에 tfstate 파일을 저장하기 위해서는 먼저 tfstate 파일을 저장할 버킷을 생성해야 한다. 

```bash
// terrafrom state 파일용 lock 테이블
resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "TerraformStateLock"
  # read_capacity = 5
  # write_capacity = 5
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"
}
```

먼저 DynamoDB 에 테이블을 만들어준다. 이 테이블은 S3 에서 tfstate 파일을 관리하면서 동시에 작업이 일어나지 않도록 하는 lock 테이블이다. lock 을 사용할지는 선택 사항이지만 원격으로 상태 파일을 관리하므로 동시에 작업하면서 인프라에 문제가 생기지 않도록 lock 테이블을 만들면 `plan` 이나 `apply` 를 할 때 먼저 lock 이 걸리고, 작업이 끝나면 lock 이 해제된다.

### log 버킷

로그 데이터를 저장할 S3 버킷을 생성한다. 이는 `terraform.tfstate` 용 S3 버킷에서 로깅을 켜서 누가 접근해서 작업했는지 알 수 있도록 여기에 기록을 남긴다. 

```bash
// 로그 저장용 버킷
resource "aws_s3_bucket" "logs" {
  bucket = "kr.ne.outsider.logs"
  acl    = "log-delivery-write"
}
```

### acl

Amazon S3 ACL(액세스 제어 목록)을 사용하면 버킷 및 객체에 대한 액세스를 관리할 수 있다.

각 버킷과 객체에는 하위 리소스로 연결된 ACL이 있다. 액세스 권한이 부여된 AWS 계정 또는 그룹과 액세스 유형을 정의합니다. 리소스에 대한 요청이 수신되면 Amazon S3는 해당 ACL을 확인하여 요청자에게 필요한 액세스 권한이 있는지 확인합니다.

[Access control list (ACL) overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl)

• **`[acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#acl)`**- 적용할 acl 이다. 유효한 값은 **`private`**, **`public-read`**, **`public-read-write`**, **`aws-exec-read`**, **`authenticated-read`**및 **`log-delivery-write`**입니다. 기본 값은 **`private`** 이다. 

### Terraform state 저장용 버킷

`terrafrom.tfstate` 가 저장되는 S3 버킷을 생성한다.

```bash
// Terraform state 저장용 S3 버킷
resource "aws_s3_bucket" "terraform-state" {
  bucket = "kako-terraform"
  # force_destroy = true # 강제 삭제
  # acl    = "private"

  # tags {
  #   Name = "kako-terraform"
  # }

# 상태파일의 버전 관리 활성화 : 코드 이력 관리
  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.logs.id}"
    target_prefix = "log/"
  }

# destroy 방지
#  lifecycle {
#    prevent_destroy = true
#  }
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

### backend 추가

[Backend Type: s3 | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

앞에서 생성한 버킷을 사용할 수 있도록 backend 를 추가해준다

```bash
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.12"

  backend "s3" {
    bucket = "kako-terraform"
    key = "terraform/test/terraform.tfstate"
    **region *= "ap-northeast-2"***
    encrypt = true    # s3 암호화 기능
    dynamodb_table  = "TerraformStateLock"
    # acl = "bucket-owner-full-control"
  }
}
```

하나의 버킷에 여러 `terraform.tfstate` 를 관리하기 위해서 키를 지정해 계층을 준다.

`encrypt` 를 설정해 [S3의 암호화 기능](https://docs.aws.amazon.com/ko_kr/AmazonS3/latest/dev/UsingServerSideEncryption.html)을 사용하도록 해준다. 암호화해서 저장하므로 혹시나 유출됐을 때 문제를 막을 수 있다.

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
