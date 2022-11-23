## 환경 설정

OS : Ubuntu 20.04

인스턴스 유형 : t2.medium

Public ip : 13.209.15.249

Private ip : 172.31.0.65

Docker version : 20.10.21

## Jenkins Install

참고 ) [https://www.jenkins.io/doc/book/installing/linux/](https://www.jenkins.io/doc/book/installing/linux/)

```bash
$ wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
$ sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
$ sudo apt update
$ sudo apt install jenkins
```

### 에러 발생

```bash
● jenkins.service - Jenkins Continuous Integration Server
     Loaded: loaded (/lib/systemd/system/jenkins.service; enabled; vendor preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Tue 2022-11-22 01:07:24 UTC; 8ms ago
    Process: 8649 ExecStart=/usr/bin/jenkins (code=exited, status=1/FAILURE)
   Main PID: 8649 (code=exited, status=1/FAILURE)

Nov 22 01:07:24 ip-172-31-0-65 systemd[1]: jenkins.service: Main process exited, code=exited, status=1/FAILURE
Nov 22 01:07:24 ip-172-31-0-65 systemd[1]: jenkins.service: Failed with result 'exit-code'.
Nov 22 01:07:24 ip-172-31-0-65 systemd[1]: Failed to start Jenkins Continuous Integration Server.
dpkg: error processing package jenkins (--configure):
 installed jenkins package post-installation script subprocess returned error exit status 1
Errors were encountered while processing:
 jenkins
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

### 해결 방법 1

dpkg 데이터베이스 재구성을 시도한 후 jenkins를 강제로 설치

$ sudo dpkg --configure -a

$ sudo apt-get 설치 -f

—> 같은 오류 발생

### 해결 방법 2

자바 버전 변경 이후 재설치

—> 재설치 해도 같은 오류 발생함

### 해결 방법 3

기존에 8080 포트를 사용하고 있는 것이 있을 경우

—> 8080 포트를 사용하고 있는 것이 없었기 때문에 이 오류는 아님

### 최종 결론

Ubuntu 20.04 에서 젠킨스를 설치 시 공식 문서 상의 설치 방법 외에 더 해주어야 할 환경 설정이 있고 이는 사용성이 떨어진다고 판단함

어느 인스턴스 에서든지 쉽게 설치할 수 있고 설정 충돌이 일어나지 않도록 하기 위해 컨테이너로 설치하는 방법을 선택함

## Jenkins Install with Docker

참고 ) [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)

참고 ) [https://hub.docker.com/_/jenkins](https://hub.docker.com/_/jenkins)

### ****Set up the repository****

```bash
# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
$ sudo apt-get update
$ sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker’s official GPG key:
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Use the following command to set up the repository:
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
$ sudo docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.
...

```

### ****Install Docker Engine****

```bash
# Update the apt package index:
$ sudo apt-get update

# Install Docker Engine, containerd, and Docker Compose.
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify that the Docker Engine installation is successful by running the hello-world image:
$ sudo docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

### Download Jenkins Image

```bash
$ docker pull jenkins/jenkins:lts
```

### Start Jenkins container

```bash
$ sudo docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock \
--name jenkins -u root jenkins/jenkins:lts
```

### Confirm Password

```bash
$ docker exec -it jenkins /bin/bash
$ cat /var/jenkins_home/secrets/initialAdminPassword
56a19e...
```

## Nexus Install

### C**reate Nexus Data Storage Space**

```bash
$ mkdir /data
$ chown 200:200 /data
```

### Start Nexus **Container**

```bash
$ docker run -d --restart=always -p 8081:8081 -p 5001:5001 \
--name nexus -v /data:/nexus-data sonatype/nexus
```

### Confirm Password

```bash
# 초반 admin 비밀번호
root@master:~# cat /data/admin.password
bdb874...
```

![image](https://user-images.githubusercontent.com/93571332/203454723-eaa1d11b-da24-4c35-b6da-a8af8945f609.png)

### Create Account

참고) [https://help.sonatype.com/repomanager3/nexus-repository-administration/access-control/users?_ga=2.255699276.534647673.1669085984-302546015.1668061316](https://help.sonatype.com/repomanager3/nexus-repository-administration/access-control/users?_ga=2.255699276.534647673.1669085984-302546015.1668061316)

![image](https://user-images.githubusercontent.com/93571332/203454770-155f4ddc-60d2-47e3-954c-90551d730cf9.png)

## **Create a Private Container Image Repository**

![image](https://user-images.githubusercontent.com/93571332/203454795-25336d9f-09e3-450b-8750-e54b53128ae0.png)

현재 접속은 https 가 아닌 http 로의 접속이므로 이를 허용

```bash
$ vi /etc/docker/daemon.json
{
	"insecure-registries" : [ "13.209.15.249:5001" ]
}
```

## Jenkins Setting

### Set Up Jenkins Credentials

이때, github의 비밀번호의 경우는 토큰값으로 해주어야 한다.

nexus는 비밀번호 입력 가능

![image](https://user-images.githubusercontent.com/93571332/203454839-e3ebb1e9-73ce-48bf-9485-e39ad9cd2914.png)

### Install Docker ****Plugin****

도커 플러그인 설치

![image](https://user-images.githubusercontent.com/93571332/203454877-f2dd1958-95cc-4de0-9a4f-c81ddafff900.png)

## Create item

![image](https://user-images.githubusercontent.com/93571332/203454915-73903ee4-c0d8-4959-becc-aa3556ff9d71.png)

![image](https://user-images.githubusercontent.com/93571332/203454936-cb554c02-9d32-49af-b537-e1b6b8f0bb05.png)

![image](https://user-images.githubusercontent.com/93571332/203454958-0c082a81-d279-4e73-9538-51d6799bd5f5.png)

## G**ithub registry configuration**

![image](https://user-images.githubusercontent.com/93571332/203454987-640f28a6-f8b9-4e27-a242-30acd1929643.png)

```bash
**[Dockerfile]**
FROM python:3.9-slim
COPY . /app
RUN pip3 install flask
WORKDIR /app
CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0"]
```

```bash
**[app.py]**
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello Flask Test'

if __name__ == '__main__':
    app.run()
```

```bash
**[Jenkinsfile]**
pipeline {
    agent any
    environment{
        NEXUS_CREDS = credentials('nexus')
    }
    stages {
        stage('Clone Repo') {
            steps {
                checkout scm
                sh 'ls *'
            }
        }
        stage('Build Image') {
            steps {
		            sh '/etc/init.d/docker start'
	              sh 'docker build -t 13.209.15.249:5001/flask_test:$BUILD_NUMBER .'
            }
        }
        stage('Docker Login') {
            steps {
                sh 'echo $NEXUS_CREDS_PSW | docker login 13.209.15.249:5001 -u $NEXUS_CREDS_USR --password-stdin'                
            }
        }
        stage('Docker Push') {
            steps {
                sh 'docker push 13.209.15.249:5001/flask_test:$BUILD_NUMBER'
            }
        }
    }
    post {
        always {
            sh 'docker logout 13.209.15.249:5001'
        }
    }
}
```

## Start Build

### 에러 발생 1

‘/var/jenkins_home/workspace/ci_test01@tmp/durable-db2ed2c2/script.sh: 1: docker: not found’

‘jenkins cannot connect to the docker daemon at unix:///var/run/docker.sock. is the docker daemon running?’

젠킨스 컨테이너 상에서 도커 명령어가 실행되지 않아 발생하는 문제

### 젠킨스 컨테이너 상에서 도커 설치

참고 ) [https://postlude.github.io/2020/12/26/docker-in-docker/](https://postlude.github.io/2020/12/26/docker-in-docker/)

도커 실행할 때 ‘-v /var/run/docker.sock:/var/run/docker.sock’ 추가

```bash
# docker container rm ... 이후,
$ docker run -d --restart=always -p 8080:8080 \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /jenkins:/var/jenkins_home --name jenkins -u root jenkins/jenkins:lts
```

### 에러 발생 2

참고 ) [https://boying-blog.tistory.com/82](https://boying-blog.tistory.com/82)

컨테이너 내부에서 ‘apt-get install -y docker-ce-cli’ 시, “Package 'docker-ce-cli' has no installation candidate”

```bash
$ apt-get update
$ apt-get install \
   ca-certificates \
   curl \
   gnupg \
   lsb-release
   
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
$ apt-get install software-properties-common
$ apt-get update
$ add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
$ apt-get update
$ apt-get install docker-ce docker-ce-cli containerd.io
```

위에 명령어를 실행해도 에러가 해결되지 않음

참고 ) [https://www.bundleapps.io/blog/docker-series/pt-1-installing-docker-and-docker-compose](https://www.bundleapps.io/blog/docker-series/pt-1-installing-docker-and-docker-compose)

```bash
$ apt-get install -y docker.io
$ groupadd docker
$ usermod -aG docker jenkins
$ chmod 666 /var/run/docker.sock
```

### 에러 발생 3

참고 ) [https://waspro.tistory.com/513](https://waspro.tistory.com/513)

‘docker login 13.209.15.249:5001’ 이 안되는 문제 발생

외부 사용자가 Docker pull을 실행할 수 있도록 하기 위해서 Docker Bearer Token Realm 추가

![image](https://user-images.githubusercontent.com/93571332/203455030-0cb18088-664c-44dd-9580-cb33a3b981b6.png)

### 에러 발생 4

nexus로 docker login 은 되었으나 docker image push 명령어 실행할때, ‘unauthorized: access to the requested resource is not authorized’ 에러 발생

확인해보니 admin으로 로그인 했을 때는 push가 되지만 user01으로 로그인 했을 때는 push가 안되는 것을 확인하고 Role 을 확인해봄

![image](https://user-images.githubusercontent.com/93571332/203455050-e105908b-7a64-4227-9f00-825142a006d9.png)

![image](https://user-images.githubusercontent.com/93571332/203455068-86c46501-8235-4cd4-a769-be6eb4515f9d.png)

위에 사진과 같이 user01 role을 생성하고, user01 계정 Granted 에 user01 역할 추가

### UI에서 빌드 확인

![image](https://user-images.githubusercontent.com/93571332/203455090-967a2e08-941d-49a8-b29c-fdd2faf4e693.png)

![image](https://user-images.githubusercontent.com/93571332/203455097-d54acec4-f5f9-48d9-ad55-21d4ebc15e49.png)

## Webhook Setting

### Install Github Integration ****Plugin****

![image](https://user-images.githubusercontent.com/93571332/203455104-98c579f2-6406-41bd-8aef-735d72b60afc.png)

### Change Setting on Pipeline

대시보드에서 전에 앞에서 만든 item (ci_test01) 의 구성으로 가서 아래와 같은 설정을 추가한다.

![image](https://user-images.githubusercontent.com/93571332/203455658-d560e6b8-d219-4a36-8b7e-eeecaab1ead7.png)

### Add Webhook

![image](https://user-images.githubusercontent.com/93571332/203455157-5ca3e816-8301-4459-be48-f3bf9e4f416c.png)

### 에러 발생

참고 ) [https://github.com/jenkins-x/jx/issues/5633](https://github.com/jenkins-x/jx/issues/5633)

host에 연결이 실패하는 오류 

![image](https://user-images.githubusercontent.com/93571332/203455197-65b1c194-319a-4d23-a509-9a278880dcdb.png)

github webhook의 자체 ip 주소를 aws 의 보안 그룹에 추가해주니 해결

![image](https://user-images.githubusercontent.com/93571332/203455211-a09d0369-724d-4662-a765-b5cc3afcf98f.png)

![image](https://user-images.githubusercontent.com/93571332/203455238-851e338b-4cb3-4d0d-9037-8a6d2f75420e.png)
