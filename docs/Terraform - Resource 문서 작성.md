# 🌑 Resource 란?
- Terraform을 구성하는 가장 중요한 구성 요소이다.
- resource를 선언함으로 AWS, GCP, Azure, openstack과 같은 provider에 해당하는 infra(network, instance 등)를 구성할 수 있다
- Terraform provider의 documentation를 참고하자
  - https://registry.terraform.io/search/providers?namespace=hashicorp provider
  - ❗ 잠깐 ❗ 
    - terraform에서 provider를 정의할때 public cloud의 경우 credentials 정보를 작성하게 되는데, 만약 credentials 정보가 source code에 모두 포함이 되어 제 3자에게 넘어가 악용된다면 엄청난 비용을 물어줄수 있다.
    - 악용 사례 https://news.mt.co.kr/mtview.php?no=2022050915224197505&VBCC_P     
    - 그렇다면 credentials 정보를 어떻게 안전하게 terraform 에게 전달해 줄 수 있을까❓
      - 다양한 방법(환경변수, aws credentials 파일 등)이 있지만 정보 유출에 경각심을 가질 수 있도록 직접 찾아보길 바란다. ( 절때 귀찮아서 그런것이 아닙니다. 🌝 )
## 🌒 resource 기본 문법 (Resource sources 와 Data sources) 
### Resource sources
- 다음과 같이 resource type을 선언하여 원하는 resource를 생성할 수 있다.
```
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }
}
```
- terraform은 resource "resource type" "resoure name" 으로 구성된다.
- resource type은 내가 어떤 csp의 provider를 사용하는가에 따라 type이 달라지므로 documentation를 참고하자.
- resource name은 resource type의 이름을 선언해 주는 것이다
  - "resource name"은 같은 "resource type"을 사용할때 중복 사용이 허용되지 않는다. (error 발생)
    - 예시
      ```
      [error]
      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
        instance_type  = "t2.micro" 
        tags = {
          "Name" = "kakao-ec2-1"
        }
      }

      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
        instance_type  = "t2.micro"
        tags = {
          "Name" = "kakao-ec2-2"
        }
      }
      ```
  - 하지만 다른 "resource type"을 사용할 경우에는 같은 "resource name"을 사용할 수 있다.
    - 예시
      ```
      [complete]
      resource "aws_iam_user" "example" {
        name = "example"
      }

      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
        instance_type  = "t2.micro" 
        tags = {
          "Name" = "kakao-ec2-1"
        }
      }
      ```
- resource block 내부에 있는 arguments(resource 를 생성하기 위한 정보)의 name은 해당하는 resource 생성시 나타나는 이름이라고 생각하면 된다. 
- resource Arguments에 대한 자세한 정보는 Terraform provider의 Argument Reference를 참고하자!
- Argument Reference를 보게 되면 아래와 같이 'Required'과 'Optional'로 나뉜다 
![image](https://user-images.githubusercontent.com/88362207/200729917-293e9e8a-941c-4981-aa6b-152e6e9586c4.png)
  - 'Required' - resource 생성시 반드시 명시되어야 하는 Argument이다.
  - 'Optional' - 추가적으로 resource의 세부사항을 control하고 싶을때 명시하는 Argument이다.
### Data sources
- Data sources는 terraform을 사용하지 않고, 만든 resource 혹은 Terraform을 통해 만들어진 resource의 Data를 가져오는데 사용된다.
- 즉, 이미 클라우드 콘솔에 존재하는 리소스를 가져오는 것이다.
- 예시
```
data "aws_ami" "kakao_ubuntu_image" {
  owners = ["self"] # AWS 계정 ID(현재 계정) 또는 AWS 소유자 별칭(예: , , ).selfamazonaws-marketplacemicrosoft
  most_recent = true # 가장 최신 버전 사용
  
  filter {
    name   = "kakao_ubuntu_image" # 생성한 AMI Name
    values = ["aws-ami-kakao-*"] # 생성한 AMI 이름
  }
}

# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = data.aws_ami.kakao_ubuntu_image.id  # 이미지
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }
}
```
- data block을 통해 생성되어 있는 filter의 name을 통해 해당 aws_ami를 가져온다. 
- 가져온 정보를 통해 EC2 resource ami에 적용시킨다.
---

## 🌓 Terraform 리소스 종속성
- Terraform은 선언형 언어이기 때문에 리소스에 종속성 선언이 있다면 Terraform 엔진이 파악하게 되고 순서대로 작업을 진행하게 된다.
### 비 종속성
- 다른 리소스와 의존성을 가지고 있지 않은 리소스는 다른 리소스와 동시에 만들어 질 수 있다.
- 예시
```
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }
}

# S3 bucket 생성
resource "aws_s3_bucket" "kakao_state" {
   bucket        = "kakao-terraform"
   force_destroy = true # 강제 삭제
   tags = {
     "Name" = "kakao-terraform"
   }
}
```
- 현재 EC2와 S3 bucket은 서로간의 의존성이 없기 때문에 동시에 생성이 가능하다.
### 암시적 종속성
- VPC를 사용하는 EC2(instance) resource를 선언하면, 암시적으로 Terraform 엔진이 순서대로 네트워크를 설정하고, 설정한 네트워크를 사용하는 EC2(instance)를 나중에 생성한다.
```
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
  subnet_id = aws_subnet.kakao_pub_a.id
# EC2 이름   
  tags = {
    "Name" = "kakao-ec2"
   }
}
```
- 현재 EC2 생성 시 subnet의 id가 필요하므로 순서대로 VPC의 subnet 생성 후 EC2를 생성하게 된다
### 명시적 종속성
- resource를 선언 할 때 사용자가 직접 리소스 간 의존성을 명시적으로 정의한다. 
```
# S3 bucket 생성
resource "aws_s3_bucket" "kakao_bucket" {
  bucket = "kakao-bucket"
}

# EC2(instance) 생성
resource "aws_instance" "kakao_ec2"
  ami           = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type = "t2.micro"
  # 위에서 생성한 S3에 파일을 push 하는 작업을 수행하는 user data
  user_data = "~~~~~~"
  
  depends_on = [
    aws_s3_bucket.kakao_bucket
  ]
}
```
- EC2(instance)는 depends_on을 통해 S3 bucket에 의존하고 있다. 
---



## 🌔 Meta-Arguments 란?
- 모든 resource 가 공통적으로 사용 할 수 있는 Arguments 가 있는데, 이것을 Meta-Arguments 라고 부른다.
- 아래와 같이 5가지의 Meta-Argument 종류가 있다.
  - depends_on
  - count
  - for_each
  - provider
  - lifecycle
## Meta-Arguments 사용법
### depends_on
- 명시적 종속성에 해당한다.
- 특정 resource에 dependency를 설정
- dependency를 설정함으로 resource들의 실행 순서 설정이 가능하다.
- 대부분 terraform에서 실행 순서를 알아서 처리하지만, 특별한 경우에만 사용하고 comment 작성이 필요하다.
- 예시
```
S3 bucket 하나와 EC2 instance 하나를 생성해야 하며, EC2 instance 생성 시 S3에 파일을 push 하는 작업을 수행한다.
```
```
# S3 bucket 생성
resource "aws_s3_bucket" "kakao_bucket" {
  bucket = "kakao-bucket"
}

# EC2(instance) 생성
resource "aws_instance" "kakao_ec2"
  ami           = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type = "t2.micro"
  # 위에서 생성한 S3에 파일을 push 하는 작업을 수행하는 user data
  user_data = "~~~~~~"
  
  depends_on = [
    aws_s3_bucket.kakao_bucket
  ]
}
```
- 설명 
  - S3 bucket이 없다면 EC2에 명시한 user_data의 설정이 S3에 push하는 작업이 수행 될 수 없으므로 S3에 적용되지 않는다.
  - EC2 resource는 S3 resource에 대한 dependency를 가지고 있음을 terraform에게 명시적으로 알려주는 것이다.
  - 그렇기 때문에 S3를 먼저 생성한 후 EC2를 생성하여 user_data를 적용한다.  
    - depends_on을 설정하게 되면 지정된 리소스가 생성될 때까지 종속 리소스 생성을 기다리므로 terraform이 인프라를 생성하는데 걸리는 시간이 늘어날 수 있다.
- ※ 그렇다면 terraform resource를 생성할때 전부 dependency를 고려하여 depends_on을 추가해야 하는가? 
  - 그렇지 않다. 
  - terraform은 암시적 종속성에 따라 자동으로 bucket이 EC2에 대한 dependency를 가지고 있음을 알고, bucket을 생성한 후 에 EC2를 생성하게 된다.
  - 이해가 되지 않는다면 'Terraform 리소스 종속성'을 다시 읽어보자!!   
### count
- 일반적으로 resource block을 통해 resource를 생성하면 1개의 resource가 생성된다.
- 동일한 resource block으로 여러 개의 동일한 resource type을 생성하고 싶을 때 사용한다.
- 예제
```
resource "aws_iam_user" "kakao_user" {
count = 3
name = "kakao-user-${count.index}+1" # ${count.index}만 사용시 0부터 시작
}
```
- 3개의 동일한 iam user 생성
- kakao-user-1, kakao-user-2, kakao-user-3 생성
- count object
  - count argument를 사용할 시 count object를 resource block 안에서 사용할 수 있다.
  - count object를 통해 생성되는 resource는 index 값을 count.index 방식으로 가져올 수 있다.
- resource instance 참조
- count argument를 사용해 생성한 resource는 참조하기 위해서는 <RESOURCE TYPE>.<NAME>[<INDEX>] 문법을 사용하여 resource의 index를 명시주어야 한다.
  - 예시
  ```
  aws_iam_user.kakao_user[0]
  aws_iam_user.kakao_user[1].name 
  aws_iam_user.kakao_user[2].id
  ```
### for_each
- count와 동일하게 한개의 resource block으로 여러 개의 동일 resource type을 생성하고자 할 때 사용한다.
- count와 for_each는 resource block에서 동시에 사용할 수 없음으로 한개만 선택해서 사용한다.
- for each는 map 혹은 set을 값으로 가질 수 있고, map 혹은 set을 통해 전달된 값의 갯수 만큼 resource를 생성한다.
  - set - 유일한 값의 요소들로 이루어진 list [1,2,3]
  - map - Key-Value 형식의 데이터 { Key : Value }
- 예시
```
# Using set (set을 사용하여 user1, user2, user3 생성)
resource "aws_iam_user" "kakao_user1" {
    for_each = toset(["user1", "user2", "user3"])
    name = each.key # map 을 사용시에는 key 값을, set 을 사용시에는 member 값을 의미
}
  
# Using map (map을 사용하여 user4, user5, user6을 tag4, tag5 tag6 태그와 함께 생성)
resource "aws_iam_user" "kakao_user2" {
    for_each = {
      user4 = "tag4"
      user5 = "tag5"
      user6 = "tag6"
    }
    name = each.key # map 을 사용시에는 key 값을, set 을 사용시에는 member 값을 의미
    tags = {
       example = each.value #  map 을 사용사에는 value 값을, set 을 사용시에는 each.key 와 동일하게 member 값을 의미
    }
}
```
### provider
- 다른 configuration을 가지고 (예 다른 region) resource를 생성해야 할 경우에 사용한다.
- 예제
```
#1 default configuration (기본적으로 사용할 region 구성이며, provider 당 반드시 1개만 선언 할 수 있다.)
provider "aws" {
region = "us-east-1"
}
#1
resource "aws_instance" "us-east-1" {
ami = "ami-example"
instance_type = "t2.micro"
}  
  
#2 alternate (alias를 선언하여 해당 하는 region에 resource를 생성하고 싶을 때 사용한다.)
provider "aws" {
alias = "seoul"
region = "ap-northeast-2"
}
#2   
resource "aws_instance" "ap-northeast-2" {
provider = aws.seoul  # 다음과 같이 선언함으로 seoul region에 instance를 생성한다.
ami = "ami-example"
instance_type = "t2.micro"
}
  
```
### lifecycle
- resource의 생성, 수정, 삭제하는 동작을 수행할 때 사용자가 원하는 방식으로 변경하기 위해 사용
- argument에는 총 3가지 방식이 있다.
#### create_before_destroy
- 예시
```
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    create_before_destroy = true
  }
}
```
- 특정 resource에 대해 update를 해야하나 제약사항에 의해 update가 불가능한 경우 만들어진 resource를 삭제
하고 update된 resource를 새로 만드는 것이 기본 동작.
- create_before_destroy = true로 설정시 먼저 update된 resource를 생성하고, 그 후 기존 resource를 삭제하는 방식으로 동작한다. 
- resource type에 따라 다른 제약 사항으로 수행이 불가능 할 수 있다.
#### prevent_destroy
- 예시
```
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    prevent_destroy = true
  }
}
```  
- 생성된 resource들 중에서 삭제 되는 것을 방지하고자 할때 사용하는 argument
####  ignore_changes
- 예시
```
### 방법 1 ( 비교 대상에서 제외하고자 하는 값을 list 안에 명시 )
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    ignore_changes = [
      instance_type,
      tags
   ]
  }
}

### 방법 2 ( 모든 arguments 를 비교대상에서 제외 )
# EC2 생성
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS 사용
  instance_type  = "t2.micro"  
# EC2 이름 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    ignore_changes = all
  }
}
```  
- 실제 적용되어 있는 resource들의 값과 code로 작성되어 적용하고자 하는 값들을 비교하여 해당 resource의 create, update, destroy를 결정한다.
- 제 3자가 console을 통하여 resource의 값을 수정했다면 terraform update 시 terraform은 해당 값이 변경된 것을 확인하고, 다시 code에 있는 값으로
원복을 수행하는 이것을 방지하기 위해 ignore_changes가 사용 된다.
- gnore_changes는 list값을 가지며, 비교 대상에서 제외하고자 하는 값을 list 안에 명시하게 되면, arguments를 terraform이 비교 대상에서 제외시켜 update를 하지 않는다.
- ignore_changes 는 list 값을 가지며 list 에 적은 arguments 를 terraform 이 비교하는 대상에서 제외시켜 update 를 하지 않음.
- 만약 모든 atguments를 비교 대상에서 제외하고자 한다면 all 값을 선언한다.

🌝 이해가 안되는 파트는 질문해 주세요
