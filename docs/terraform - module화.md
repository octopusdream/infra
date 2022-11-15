### module이란
- terraform으로 infra를 구성할 때 규모가 점점 커질경우 하나의 파일에 모든 것을 정의 한다면 의도치않게 다른 부분에 영향을 미칠 수 있고 환경별 가은 리소스의 코드가 중복될 수 있다.
- 이 단점을 해결하기 위해서 terraform은 리소스의 코드가 중복되어 쌓일수 있다.
- 모듈은 관련 요소들을 하나로 모아 패키지를 만드는데, 예를 들면 VPC 모듈의 경우 vpc, subnet, gateway 등 리소스를 하나의 패키징을 한다.

---
### module의 장점
- 모듈의 장점으로는 총 3가지로 요약할 수 있다.
  - 캡슐화 - 서로 관련이 있는 요소들을 모아 캡슐화하여 의도치 않는 문제를 예방할 수 있다.
  - 재사용성 - 모듈을 사용해 리소스를 정의하면 다른 환경에서도 해당하는 리소스를 재사용할 수 있다.
  - 일관성 - 매번 새로 작성하게 되면 사용자에 따라 리소스의 옵션이 빠지거나, 같을 수 없기 때문에 모듈을 재 사용 한다면 일관성 가질 수 있다.

---
### module의 구성 절차
- terraform은 재사용하기 위해 mudule를 사용한다.
- 재사용 하기 위해 사용자가 module를 생성하고 변수 입력 값을 제거한다.
- Directory를 mudule로 변경
- staging 환경에서 module을 사용하기 위해서는 source가 존재해야 한다.
  - ※ staging 환경 - 운영 환경(Production)과 거의 동일한 환경을 만들어 놓고, 운영환경으로 이전하기 전에, 여러 가지 비 기능적인 부분 (Security, 성능, 장애등)을 검증하는 환경
- staging 한경에서의 main.tf 파일은 실제 구성하려는 환경에 대한 정보를 입력해야한다.
- terraform apply를 통해 실행 및 테스트를 진행한다.
---
### module의 기본 구조
- module은 root module과 child module로 나뉘어 진다.
  - root module 
    - terraform command가 실행 되고 있는 module
    - 필수 요소인 module
    - Root Module은 다른 Module의 기본 진입점
    - main.tf에는 Child Module의 Source 위치 또는 Module들의 연결을 정의
  - child module 
    - 다른 module (Root module 포함) 에서 호출하여 사용되는 module
    - Resource들을 정의
- 중첩 Module의 경우는 "modules/"의 하위에 위치해야 한다.
  - a. Input variables
      - 다른 Module로부터 입력받을 입력 값들을 관리
      - variables.tf 파일에 저장
  - b. Output variables
      - 다른 Module에게 반환할 출력 값들을 관리
      - output.tf 파일에 저장
  - c. Resources
      - Infrastructure Object들을 관리
      - main.tf 파일에 저장
   - d. terraform.tfstate 및 terraform.tfstate.backup
      - Terraform 상태를 포함하며, Terraform의 구성과 프로비저닝 된 인프라 간의 관계를 추적할 수 있다.
   - e. .terraform
      - 인프라를 프로비저닝 하는데 사용되는 모듈과 플러그인이 포함되어 있다.
      - .tf 파일에 정의된 인프라 구성이 아닌 Terraform의 특정 인스턴스에 한정된다.
   - f. *.tfvars
---
### module 작성 방법
- 작성 방법은 본 프로젝트에서 사용한 terraform code 예시로 사용하겠다.
- tree
```
.
│  main.tf
│  terraform.tfvars
│  variable.tf
│  outputs.tf
│ 
└─modules
    │
    ├─01_vpc
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─02_s3
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─03_sg
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─04_efs
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─05_ec2
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    └─06_auto_scaling
            main.tf
            outputs.tf
            variables.tf
```
### root module
- 아래와 같이 해당하는 부분은 root module에 해당한다.
```
.
│  main.tf
│  terraform.tfvars
│  variable.tf
│  outputs.tf
│ 
```
- root module의 기본 구성은 다음과 같다.
```
module "vpc" {
  source = "./modules/01_vpc"
}
```
- source에는 모듈로 쓰기위해 child module에 리소스를 정의해둔 폴더의 경로를 적는다.
- provider는 테라폼을 실행할 폴더 root module에 정의한다.

### child module
- 아래와 같이 해당하는 부분은 child module에 해당한다
```
└─modules
    │
    ├─01_vpc
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─02_s3
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─03_sg
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─04_efs
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    ├─05_ec2
    │      main.tf
    │      outputs.tf
    │      variables.tf
    │
    └─06_auto_scaling
            main.tf
            outputs.tf
            variables.tf
```
- child module의 기본 구성은 다음과 같다.
```
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name" = "vpc"
  }
}
```
- 모듈은 폴더 단위로 구성한다.
- modules 폴더 내에 있는 01_vpc, 02_s3, 03_sg의 구성 파일들이 각각 하나의 모듈이 되는 것이다.
### 변수 정의하는 방식
- 입력 받을 변수의 경우는 root, child 두 곳 모두에 변수를 정의해 주어야 한다.
- 기본 예시는 다음과 같다.
    - root module의 main.tf
    ```
    provider "aws" {
      region               = var.region
    }
    
    module "vpc" {
      source = "./modules/01_vpc"
      
      vpc_cidr = var.vpc_cidr
    }
    ```
    - root module의 variables.tf
    ```
    variable "region" {
      desciption = "region를 입력하세요(ex)ap-northeast-2"
    }
    
    variable "vpc_cidr" {
      description = "vpc cidr block : x.x.x.x/x를 입력하세요"
    }
    ```
        - root module의 변수를 입력 받는다.    
    - child module의 main.tf
    ```
    resource "aws_vpc" "vpc" {
      cidr_block           = var.vpc_cidr
      enable_dns_hostnames = true

      tags = {
        "Name" = "vpc"
      }
    }
    ```
    - child module의 variables.tf
    ```    
    variable "vpc_cidr" {
    }
    ```
        - 입력받은 변수를 module의 변수로 입력하고
        - 입력된 변수를 통해 resource를 생성한다.
- 변수를 입력 받지 않고 root module의 variables.tf에 직접 지정해주는 방법도 있다.
- 하지만 재사용성을 극대화하기 위하여 앞으로 상황마다 값을 바꾸어 처리하기 위해서는 변수를 입력 받는 것이 좋다.
