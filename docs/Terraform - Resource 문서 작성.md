# ๐ Resource ๋?
- Terraform์ ๊ตฌ์ฑํ๋ ๊ฐ์ฅ ์ค์ํ ๊ตฌ์ฑ ์์์ด๋ค.
- resource๋ฅผ ์ ์ธํจ์ผ๋ก AWS, GCP, Azure, openstack๊ณผ ๊ฐ์ provider์ ํด๋นํ๋ infra(network, instance ๋ฑ)๋ฅผ ๊ตฌ์ฑํ  ์ ์๋ค
- Terraform provider์ documentation๋ฅผ ์ฐธ๊ณ ํ์
  - https://registry.terraform.io/search/providers?namespace=hashicorp provider
  - โ ์ ๊น โ 
    - terraform์์ provider๋ฅผ ์ ์ํ ๋ public cloud์ ๊ฒฝ์ฐ credentials ์ ๋ณด๋ฅผ ์์ฑํ๊ฒ ๋๋๋ฐ, ๋ง์ฝ credentials ์ ๋ณด๊ฐ source code์ ๋ชจ๋ ํฌํจ์ด ๋์ด ์  3์์๊ฒ ๋์ด๊ฐ ์์ฉ๋๋ค๋ฉด ์์ฒญ๋ ๋น์ฉ์ ๋ฌผ์ด์ค์ ์๋ค.
    - ์์ฉ ์ฌ๋ก https://news.mt.co.kr/mtview.php?no=2022050915224197505&VBCC_P     
    - ๊ทธ๋ ๋ค๋ฉด credentials ์ ๋ณด๋ฅผ ์ด๋ป๊ฒ ์์ ํ๊ฒ terraform ์๊ฒ ์ ๋ฌํด ์ค ์ ์์๊นโ
      - ๋ค์ํ ๋ฐฉ๋ฒ(ํ๊ฒฝ๋ณ์, aws credentials ํ์ผ ๋ฑ)์ด ์์ง๋ง ์ ๋ณด ์ ์ถ์ ๊ฒฝ๊ฐ์ฌ์ ๊ฐ์ง ์ ์๋๋ก ์ง์  ์ฐพ์๋ณด๊ธธ ๋ฐ๋๋ค. ( ์ ๋ ๊ท์ฐฎ์์ ๊ทธ๋ฐ๊ฒ์ด ์๋๋๋ค. ๐ )
## ๐ resource ๊ธฐ๋ณธ ๋ฌธ๋ฒ (Resource sources ์ Data sources) 
### Resource sources
- ๋ค์๊ณผ ๊ฐ์ด resource type์ ์ ์ธํ์ฌ ์ํ๋ resource๋ฅผ ์์ฑํ  ์ ์๋ค.
```
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }
}
```
- terraform์ resource "resource type" "resoure name" ์ผ๋ก ๊ตฌ์ฑ๋๋ค.
- resource type์ ๋ด๊ฐ ์ด๋ค csp์ provider๋ฅผ ์ฌ์ฉํ๋๊ฐ์ ๋ฐ๋ผ type์ด ๋ฌ๋ผ์ง๋ฏ๋ก documentation๋ฅผ ์ฐธ๊ณ ํ์.
- resource name์ resource type์ ์ด๋ฆ์ ์ ์ธํด ์ฃผ๋ ๊ฒ์ด๋ค
  - "resource name"์ ๊ฐ์ "resource type"์ ์ฌ์ฉํ ๋ ์ค๋ณต ์ฌ์ฉ์ด ํ์ฉ๋์ง ์๋๋ค. (error ๋ฐ์)
    - ์์
      ```
      [error]
      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
        instance_type  = "t2.micro" 
        tags = {
          "Name" = "kakao-ec2-1"
        }
      }

      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
        instance_type  = "t2.micro"
        tags = {
          "Name" = "kakao-ec2-2"
        }
      }
      ```
  - ํ์ง๋ง ๋ค๋ฅธ "resource type"์ ์ฌ์ฉํ  ๊ฒฝ์ฐ์๋ ๊ฐ์ "resource name"์ ์ฌ์ฉํ  ์ ์๋ค.
    - ์์
      ```
      [complete]
      resource "aws_iam_user" "example" {
        name = "example"
      }

      resource "aws_instance" "example" {
        ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
        instance_type  = "t2.micro" 
        tags = {
          "Name" = "kakao-ec2-1"
        }
      }
      ```
- resource block ๋ด๋ถ์ ์๋ arguments(resource ๋ฅผ ์์ฑํ๊ธฐ ์ํ ์ ๋ณด)์ name์ ํด๋นํ๋ resource ์์ฑ์ ๋ํ๋๋ ์ด๋ฆ์ด๋ผ๊ณ  ์๊ฐํ๋ฉด ๋๋ค. 
- resource Arguments์ ๋ํ ์์ธํ ์ ๋ณด๋ Terraform provider์ Argument Reference๋ฅผ ์ฐธ๊ณ ํ์!
- Argument Reference๋ฅผ ๋ณด๊ฒ ๋๋ฉด ์๋์ ๊ฐ์ด 'Required'๊ณผ 'Optional'๋ก ๋๋๋ค 
![image](https://user-images.githubusercontent.com/88362207/200729917-293e9e8a-941c-4981-aa6b-152e6e9586c4.png)
  - 'Required' - resource ์์ฑ์ ๋ฐ๋์ ๋ช์๋์ด์ผ ํ๋ Argument์ด๋ค.
  - 'Optional' - ์ถ๊ฐ์ ์ผ๋ก resource์ ์ธ๋ถ์ฌํญ์ controlํ๊ณ  ์ถ์๋ ๋ช์ํ๋ Argument์ด๋ค.
### Data sources
- Data sources๋ terraform์ ์ฌ์ฉํ์ง ์๊ณ , ๋ง๋  resource ํน์ Terraform์ ํตํด ๋ง๋ค์ด์ง resource์ Data๋ฅผ ๊ฐ์ ธ์ค๋๋ฐ ์ฌ์ฉ๋๋ค.
- ์ฆ, ์ด๋ฏธ ํด๋ผ์ฐ๋ ์ฝ์์ ์กด์ฌํ๋ ๋ฆฌ์์ค๋ฅผ ๊ฐ์ ธ์ค๋ ๊ฒ์ด๋ค.
- ์์
```
data "aws_ami" "kakao_ubuntu_image" {
  owners = ["self"] # AWS ๊ณ์  ID(ํ์ฌ ๊ณ์ ) ๋๋ AWS ์์ ์ ๋ณ์นญ(์: , , ).selfamazonaws-marketplacemicrosoft
  most_recent = true # ๊ฐ์ฅ ์ต์  ๋ฒ์  ์ฌ์ฉ
  
  filter {
    name   = "kakao_ubuntu_image" # ์์ฑํ AMI Name
    values = ["aws-ami-kakao-*"] # ์์ฑํ AMI ์ด๋ฆ
  }
}

# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = data.aws_ami.kakao_ubuntu_image.id  # ์ด๋ฏธ์ง
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }
}
```
- data block์ ํตํด ์์ฑ๋์ด ์๋ filter์ name์ ํตํด ํด๋น aws_ami๋ฅผ ๊ฐ์ ธ์จ๋ค. 
- ๊ฐ์ ธ์จ ์ ๋ณด๋ฅผ ํตํด EC2 resource ami์ ์ ์ฉ์ํจ๋ค.
---

## ๐ Terraform ๋ฆฌ์์ค ์ข์์ฑ
- Terraform์ ์ ์ธํ ์ธ์ด์ด๊ธฐ ๋๋ฌธ์ ๋ฆฌ์์ค์ ์ข์์ฑ ์ ์ธ์ด ์๋ค๋ฉด Terraform ์์ง์ด ํ์ํ๊ฒ ๋๊ณ  ์์๋๋ก ์์์ ์งํํ๊ฒ ๋๋ค.
### ๋น ์ข์์ฑ
- ๋ค๋ฅธ ๋ฆฌ์์ค์ ์์กด์ฑ์ ๊ฐ์ง๊ณ  ์์ง ์์ ๋ฆฌ์์ค๋ ๋ค๋ฅธ ๋ฆฌ์์ค์ ๋์์ ๋ง๋ค์ด ์ง ์ ์๋ค.
- ์์
```
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }
}

# S3 bucket ์์ฑ
resource "aws_s3_bucket" "kakao_state" {
   bucket        = "kakao-terraform"
   force_destroy = true # ๊ฐ์  ์ญ์ 
   tags = {
     "Name" = "kakao-terraform"
   }
}
```
- ํ์ฌ EC2์ S3 bucket์ ์๋ก๊ฐ์ ์์กด์ฑ์ด ์๊ธฐ ๋๋ฌธ์ ๋์์ ์์ฑ์ด ๊ฐ๋ฅํ๋ค.
### ์์์  ์ข์์ฑ
- VPC๋ฅผ ์ฌ์ฉํ๋ EC2(instance) resource๋ฅผ ์ ์ธํ๋ฉด, ์์์ ์ผ๋ก Terraform ์์ง์ด ์์๋๋ก ๋คํธ์ํฌ๋ฅผ ์ค์ ํ๊ณ , ์ค์ ํ ๋คํธ์ํฌ๋ฅผ ์ฌ์ฉํ๋ EC2(instance)๋ฅผ ๋์ค์ ์์ฑํ๋ค.
```
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
  subnet_id = aws_subnet.kakao_pub_a.id
# EC2 ์ด๋ฆ   
  tags = {
    "Name" = "kakao-ec2"
   }
}
```
- ํ์ฌ EC2 ์์ฑ ์ subnet์ id๊ฐ ํ์ํ๋ฏ๋ก ์์๋๋ก VPC์ subnet ์์ฑ ํ EC2๋ฅผ ์์ฑํ๊ฒ ๋๋ค
### ๋ช์์  ์ข์์ฑ
- resource๋ฅผ ์ ์ธ ํ  ๋ ์ฌ์ฉ์๊ฐ ์ง์  ๋ฆฌ์์ค ๊ฐ ์์กด์ฑ์ ๋ช์์ ์ผ๋ก ์ ์ํ๋ค. 
```
# S3 bucket ์์ฑ
resource "aws_s3_bucket" "kakao_bucket" {
  bucket = "kakao-bucket"
}

# EC2(instance) ์์ฑ
resource "aws_instance" "kakao_ec2"
  ami           = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type = "t2.micro"
  # ์์์ ์์ฑํ S3์ ํ์ผ์ push ํ๋ ์์์ ์ํํ๋ user data
  user_data = "~~~~~~"
  
  depends_on = [
    aws_s3_bucket.kakao_bucket
  ]
}
```
- EC2(instance)๋ depends_on์ ํตํด S3 bucket์ ์์กดํ๊ณ  ์๋ค. 
---



## ๐ Meta-Arguments ๋?
- ๋ชจ๋  resource ๊ฐ ๊ณตํต์ ์ผ๋ก ์ฌ์ฉ ํ  ์ ์๋ Arguments ๊ฐ ์๋๋ฐ, ์ด๊ฒ์ Meta-Arguments ๋ผ๊ณ  ๋ถ๋ฅธ๋ค.
- ์๋์ ๊ฐ์ด 5๊ฐ์ง์ Meta-Argument ์ข๋ฅ๊ฐ ์๋ค.
  - depends_on
  - count
  - for_each
  - provider
  - lifecycle
## Meta-Arguments ์ฌ์ฉ๋ฒ
### depends_on
- ๋ช์์  ์ข์์ฑ์ ํด๋นํ๋ค.
- ํน์  resource์ dependency๋ฅผ ์ค์ 
- dependency๋ฅผ ์ค์ ํจ์ผ๋ก resource๋ค์ ์คํ ์์ ์ค์ ์ด ๊ฐ๋ฅํ๋ค.
- ๋๋ถ๋ถ terraform์์ ์คํ ์์๋ฅผ ์์์ ์ฒ๋ฆฌํ์ง๋ง, ํน๋ณํ ๊ฒฝ์ฐ์๋ง ์ฌ์ฉํ๊ณ  comment ์์ฑ์ด ํ์ํ๋ค.
- ์์
```
S3 bucket ํ๋์ EC2 instance ํ๋๋ฅผ ์์ฑํด์ผ ํ๋ฉฐ, EC2 instance ์์ฑ ์ S3์ ํ์ผ์ push ํ๋ ์์์ ์ํํ๋ค.
```
```
# S3 bucket ์์ฑ
resource "aws_s3_bucket" "kakao_bucket" {
  bucket = "kakao-bucket"
}

# EC2(instance) ์์ฑ
resource "aws_instance" "kakao_ec2"
  ami           = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type = "t2.micro"
  # ์์์ ์์ฑํ S3์ ํ์ผ์ push ํ๋ ์์์ ์ํํ๋ user data
  user_data = "~~~~~~"
  
  depends_on = [
    aws_s3_bucket.kakao_bucket
  ]
}
```
- ์ค๋ช 
  - S3 bucket์ด ์๋ค๋ฉด EC2์ ๋ช์ํ user_data์ ์ค์ ์ด S3์ pushํ๋ ์์์ด ์ํ ๋  ์ ์์ผ๋ฏ๋ก S3์ ์ ์ฉ๋์ง ์๋๋ค.
  - EC2 resource๋ S3 resource์ ๋ํ dependency๋ฅผ ๊ฐ์ง๊ณ  ์์์ terraform์๊ฒ ๋ช์์ ์ผ๋ก ์๋ ค์ฃผ๋ ๊ฒ์ด๋ค.
  - ๊ทธ๋ ๊ธฐ ๋๋ฌธ์ S3๋ฅผ ๋จผ์  ์์ฑํ ํ EC2๋ฅผ ์์ฑํ์ฌ user_data๋ฅผ ์ ์ฉํ๋ค.  
    - depends_on์ ์ค์ ํ๊ฒ ๋๋ฉด ์ง์ ๋ ๋ฆฌ์์ค๊ฐ ์์ฑ๋  ๋๊น์ง ์ข์ ๋ฆฌ์์ค ์์ฑ์ ๊ธฐ๋ค๋ฆฌ๋ฏ๋ก terraform์ด ์ธํ๋ผ๋ฅผ ์์ฑํ๋๋ฐ ๊ฑธ๋ฆฌ๋ ์๊ฐ์ด ๋์ด๋  ์ ์๋ค.
- โโ ๊ทธ๋ ๋ค๋ฉด terraform resource๋ฅผ ์์ฑํ ๋ ์ ๋ถ dependency๋ฅผ ๊ณ ๋ คํ์ฌ depends_on์ ์ถ๊ฐํด์ผ ํ๋๊ฐโ
  - ๊ทธ๋ ์ง ์๋คโ . 
  - terraform์ ์์์  ์ข์์ฑ์ ๋ฐ๋ผ ์๋์ผ๋ก bucket์ด EC2์ ๋ํ dependency๋ฅผ ๊ฐ์ง๊ณ  ์์์ ์๊ณ , bucket์ ์์ฑํ ํ ์ EC2๋ฅผ ์์ฑํ๊ฒ ๋๋ค.
  - ์ดํด๊ฐ ๋์ง ์๋๋ค๋ฉด 'Terraform ๋ฆฌ์์ค ์ข์์ฑ'์ ๋ค์ ์ฝ์ด๋ณด์โโ  
### count
- ์ผ๋ฐ์ ์ผ๋ก resource block์ ํตํด resource๋ฅผ ์์ฑํ๋ฉด 1๊ฐ์ resource๊ฐ ์์ฑ๋๋ค.
- ๋์ผํ resource block์ผ๋ก ์ฌ๋ฌ ๊ฐ์ ๋์ผํ resource type์ ์์ฑํ๊ณ  ์ถ์ ๋ ์ฌ์ฉํ๋ค.
- ์์ 
```
resource "aws_iam_user" "kakao_user" {
count = 3
name = "kakao-user-${count.index}+1" # ${count.index}๋ง ์ฌ์ฉ์ 0๋ถํฐ ์์
}
```
- 3๊ฐ์ ๋์ผํ iam user ์์ฑ
- kakao-user-1, kakao-user-2, kakao-user-3 ์์ฑ
- count object
  - count argument๋ฅผ ์ฌ์ฉํ  ์ count object๋ฅผ resource block ์์์ ์ฌ์ฉํ  ์ ์๋ค.
  - count object๋ฅผ ํตํด ์์ฑ๋๋ resource๋ index ๊ฐ์ count.index ๋ฐฉ์์ผ๋ก ๊ฐ์ ธ์ฌ ์ ์๋ค.
- resource instance ์ฐธ์กฐ
- count argument๋ฅผ ์ฌ์ฉํด ์์ฑํ resource๋ ์ฐธ์กฐํ๊ธฐ ์ํด์๋ <RESOURCE TYPE>.<NAME>[<INDEX>] ๋ฌธ๋ฒ์ ์ฌ์ฉํ์ฌ resource์ index๋ฅผ ๋ช์์ฃผ์ด์ผ ํ๋ค.
  - ์์
  ```
  aws_iam_user.kakao_user[0]
  aws_iam_user.kakao_user[1].name 
  aws_iam_user.kakao_user[2].id
  ```
### for_each
- count์ ๋์ผํ๊ฒ ํ๊ฐ์ resource block์ผ๋ก ์ฌ๋ฌ ๊ฐ์ ๋์ผ resource type์ ์์ฑํ๊ณ ์ ํ  ๋ ์ฌ์ฉํ๋ค.
- count์ for_each๋ resource block์์ ๋์์ ์ฌ์ฉํ  ์ ์์์ผ๋ก ํ๊ฐ๋ง ์ ํํด์ ์ฌ์ฉํ๋ค.
- for each๋ map ํน์ set์ ๊ฐ์ผ๋ก ๊ฐ์ง ์ ์๊ณ , map ํน์ set์ ํตํด ์ ๋ฌ๋ ๊ฐ์ ๊ฐฏ์ ๋งํผ resource๋ฅผ ์์ฑํ๋ค.
  - set - ์ ์ผํ ๊ฐ์ ์์๋ค๋ก ์ด๋ฃจ์ด์ง list [1,2,3]
  - map - Key-Value ํ์์ ๋ฐ์ดํฐ { Key : Value }
- ์์
```
# Using set (set์ ์ฌ์ฉํ์ฌ user1, user2, user3 ์์ฑ)
resource "aws_iam_user" "kakao_user1" {
    for_each = toset(["user1", "user2", "user3"])
    name = each.key # map ์ ์ฌ์ฉ์์๋ key ๊ฐ์, set ์ ์ฌ์ฉ์์๋ member ๊ฐ์ ์๋ฏธ
}
  
# Using map (map์ ์ฌ์ฉํ์ฌ user4, user5, user6์ tag4, tag5 tag6 ํ๊ทธ์ ํจ๊ป ์์ฑ)
resource "aws_iam_user" "kakao_user2" {
    for_each = {
      user4 = "tag4"
      user5 = "tag5"
      user6 = "tag6"
    }
    name = each.key # map ์ ์ฌ์ฉ์์๋ key ๊ฐ์, set ์ ์ฌ์ฉ์์๋ member ๊ฐ์ ์๋ฏธ
    tags = {
       example = each.value #  map ์ ์ฌ์ฉ์ฌ์๋ value ๊ฐ์, set ์ ์ฌ์ฉ์์๋ each.key ์ ๋์ผํ๊ฒ member ๊ฐ์ ์๋ฏธ
    }
}
```
### provider
- ๋ค๋ฅธ configuration์ ๊ฐ์ง๊ณ  (์ ๋ค๋ฅธ region) resource๋ฅผ ์์ฑํด์ผ ํ  ๊ฒฝ์ฐ์ ์ฌ์ฉํ๋ค.
- ์์ 
```
#1 default configuration (๊ธฐ๋ณธ์ ์ผ๋ก ์ฌ์ฉํ  region ๊ตฌ์ฑ์ด๋ฉฐ, provider ๋น ๋ฐ๋์ 1๊ฐ๋ง ์ ์ธ ํ  ์ ์๋ค.)
provider "aws" {
region = "us-east-1"
}
#1
resource "aws_instance" "us-east-1" {
ami = "ami-example"
instance_type = "t2.micro"
}  
  
#2 alternate (alias๋ฅผ ์ ์ธํ์ฌ ํด๋น ํ๋ region์ resource๋ฅผ ์์ฑํ๊ณ  ์ถ์ ๋ ์ฌ์ฉํ๋ค.)
provider "aws" {
alias = "seoul"
region = "ap-northeast-2"
}
#2   
resource "aws_instance" "ap-northeast-2" {
provider = aws.seoul  # ๋ค์๊ณผ ๊ฐ์ด ์ ์ธํจ์ผ๋ก seoul region์ instance๋ฅผ ์์ฑํ๋ค.
ami = "ami-example"
instance_type = "t2.micro"
}
  
```
### lifecycle
- resource์ ์์ฑ, ์์ , ์ญ์ ํ๋ ๋์์ ์ํํ  ๋ ์ฌ์ฉ์๊ฐ ์ํ๋ ๋ฐฉ์์ผ๋ก ๋ณ๊ฒฝํ๊ธฐ ์ํด ์ฌ์ฉ
- argument์๋ ์ด 3๊ฐ์ง ๋ฐฉ์์ด ์๋ค.
#### create_before_destroy
- ์์
```
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    create_before_destroy = true
  }
}
```
- ํน์  resource์ ๋ํด update๋ฅผ ํด์ผํ๋ ์ ์ฝ์ฌํญ์ ์ํด update๊ฐ ๋ถ๊ฐ๋ฅํ ๊ฒฝ์ฐ ๋ง๋ค์ด์ง resource๋ฅผ ์ญ์ 
ํ๊ณ  update๋ resource๋ฅผ ์๋ก ๋ง๋๋ ๊ฒ์ด ๊ธฐ๋ณธ ๋์.
- create_before_destroy = true๋ก ์ค์ ์ ๋จผ์  update๋ resource๋ฅผ ์์ฑํ๊ณ , ๊ทธ ํ ๊ธฐ์กด resource๋ฅผ ์ญ์ ํ๋ ๋ฐฉ์์ผ๋ก ๋์ํ๋ค. 
- resource type์ ๋ฐ๋ผ ๋ค๋ฅธ ์ ์ฝ ์ฌํญ์ผ๋ก ์ํ์ด ๋ถ๊ฐ๋ฅ ํ  ์ ์๋ค.
#### prevent_destroy
- ์์
```
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    prevent_destroy = true
  }
}
```  
- ์์ฑ๋ resource๋ค ์ค์์ ์ญ์  ๋๋ ๊ฒ์ ๋ฐฉ์งํ๊ณ ์ ํ ๋ ์ฌ์ฉํ๋ argument
####  ignore_changes
- ์์
```
### ๋ฐฉ๋ฒ 1 ( ๋น๊ต ๋์์์ ์ ์ธํ๊ณ ์ ํ๋ ๊ฐ์ list ์์ ๋ช์ )
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
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

### ๋ฐฉ๋ฒ 2 ( ๋ชจ๋  arguments ๋ฅผ ๋น๊ต๋์์์ ์ ์ธ )
# EC2 ์์ฑ
resource "aws_instance" "kakao_instance" {
  ami            = "ami-0e9bfdb247cc8de84"  # ubuntu 22.04 LTS ์ฌ์ฉ
  instance_type  = "t2.micro"  
# EC2 ์ด๋ฆ 
  tags = {
    "Name" = "kakao-ec2"
  }   
  lifecycle {
    ignore_changes = all
  }
}
```  
- ์ค์  ์ ์ฉ๋์ด ์๋ resource๋ค์ ๊ฐ๊ณผ code๋ก ์์ฑ๋์ด ์ ์ฉํ๊ณ ์ ํ๋ ๊ฐ๋ค์ ๋น๊ตํ์ฌ ํด๋น resource์ create, update, destroy๋ฅผ ๊ฒฐ์ ํ๋ค.
- ์  3์๊ฐ console์ ํตํ์ฌ resource์ ๊ฐ์ ์์ ํ๋ค๋ฉด terraform update ์ terraform์ ํด๋น ๊ฐ์ด ๋ณ๊ฒฝ๋ ๊ฒ์ ํ์ธํ๊ณ , ๋ค์ code์ ์๋ ๊ฐ์ผ๋ก
์๋ณต์ ์ํํ๋ ์ด๊ฒ์ ๋ฐฉ์งํ๊ธฐ ์ํด ignore_changes๊ฐ ์ฌ์ฉ ๋๋ค.
- gnore_changes๋ list๊ฐ์ ๊ฐ์ง๋ฉฐ, ๋น๊ต ๋์์์ ์ ์ธํ๊ณ ์ ํ๋ ๊ฐ์ list ์์ ๋ช์ํ๊ฒ ๋๋ฉด, arguments๋ฅผ terraform์ด ๋น๊ต ๋์์์ ์ ์ธ์์ผ update๋ฅผ ํ์ง ์๋๋ค.
- ignore_changes ๋ list ๊ฐ์ ๊ฐ์ง๋ฉฐ list ์ ์ ์ arguments ๋ฅผ terraform ์ด ๋น๊ตํ๋ ๋์์์ ์ ์ธ์์ผ update ๋ฅผ ํ์ง ์์.
- ๋ง์ฝ ๋ชจ๋  atguments๋ฅผ ๋น๊ต ๋์์์ ์ ์ธํ๊ณ ์ ํ๋ค๋ฉด all ๊ฐ์ ์ ์ธํ๋ค.

๐ ์ดํด๊ฐ ์๋๋ ํํธ๋ ์ง๋ฌธํด ์ฃผ์ธ์ 
