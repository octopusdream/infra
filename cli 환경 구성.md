### **IAM 이란?**

IAM(AWS Identity and Access Management)은 AWS 리소스에 대한 액세스를 안전하게 제어할 수 있는 웹 서비스입니다. IAM을 사용하여 리소스를 사용하도록 인증 및 권한 부여된 대상을 제어합니다.

AWS 계정을 **처음 생성하는 경우**에는 전체 AWS 서비스 및 계정 리소스에 대해 완전한 액세스 권한을 지닌 **단일 로그인 자격 증명**으로 시작합니다. 이 자격 증명은 AWS 계정 루트 사용자라고 하며, 계정을 생성할 때 사용한 이메일 주소와 암호로 로그인하여 액세스합니다. 일상적인 작업, 심지어 관리 작업의 경우에도 **루트 사용자를 사용하지 마실 것**을 강력히 권장합니다. 대신, IAM 사용자를 처음 생성할 때만 루트 사용자를 사용하는 모범 사례를 준수합니다. 그런 다음 루트 사용자를 안전하게 보관해 두고 몇 가지 계정 및 서비스 관리 작업을 수행할 때만 자격 증명을 사용합니다.

-----

### IAM 사용자 추가

 콘솔 홈 → `iam` 검색 → 사용자 → 사용자 추가

> 사용자 이름 입력
액세스 키 체크
> 

→ 다음

직접 생성한 보안그룹이 있다면 보안그룹을 선택해주는 것이 좋지만 일단은 모든 권한을 위임한 보안 그룹을 생성하도록 해준다.

기존 정책 직접 연결 → AdministratorAccess 선택 → 다음

태그를 추가하는 것이 좋지만 아직은 추가하지 않고 사용자를 생성할 것이다.

→ 다음 → 사용자 만들기

사용자 생성이 완료되면 액세스 키 ID 와 비밀 액세스 키 값이 나온다. 액세스 키 ID 와 비밀 액세스 키 값을 직접 저장해두거나 csv 파일을 저장해둔다.

-----

```bash
C:\Users\user> aws configure
AWS Access Key ID [****************52MG]:
AWS Secret Access Key [****************XadK]:
Default region name [ap-northeast-2]:
Default output format [json]:
```

- vs code 설치 후 실행
- HashiCorp Terraform 설치

-----

### s3 bucket

```bash
mkdir test
cd test
```

- 연결

```bash
aws s3 ls
aws s3 mb s3://jung-terraform
aws s3 sync . s3://jung-terraform8  
```

- 확인
![image](https://user-images.githubusercontent.com/72699541/200508596-296fc2ed-4c11-423c-a02e-3ae6c89f2480.png)


-----

### terraform 테스트

```bash
vi main.tf
##### main.tf #####
provider "aws" {
  access_key = "액세스 키 ID"
  secret_key = "비밀 액세스 키 값"
  region = "ap-northeast-2"
}
```

ami 값은 아래의 링크를 통해 찾을 수 있다. 우리는 `ap-northeast-2` 에서 terraform 을 실행하니 검색 창에 `ap-northeast-2` 을 검색하여 ami 를 찾아 값을 넣어준다.

[Ubuntu Amazon EC2 AMI Finder](https://cloud-images.ubuntu.com/locator/ec2/)

```bash
##### main.tf #####
resource "aws_instance" "example" {
  ami           = "ami-08508144e576d5b64"
  instance_type = "t2.micro"
}    # main.tf 에 추가
```

- 실행

```bash
terraform init
terraform plan
terraform apply
```

위 명령어를 모두 실행하고 콘솔 홈 → 인스턴스 에서 인스턴스가 새롭게 생성된 것을 확인할 수 있다.



