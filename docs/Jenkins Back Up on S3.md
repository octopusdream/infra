## Why Back Up?

사실 CI/CD 파트는 젠킨스 서버가 죽는다고 크게 무슨 일이 발생하지는 않는다. 젠킨스 서버가 죽는다고 쿠버네티스 클러스터 상에 올려진 Pod 들이 죽거나 문제가 생기지는 않기 때문이다. 다만, 아무것도 백업되지 않은 상태로 CI/CD 를 전과 같은 상태로 복구하기는 쉽지 않다. 플러그인이 어떠한 버전으로 설치되어 있는지, CI가 어떻게 구성되었는지 이를 모두 다 전과 같은 상태로 복구하는 것은 어려운 일이다. 그래서 이번 프로젝트에서는 Jenkins 의 여러 배치와 설정파일의 정보를 가지고 있는 master 를 S3 에 백업을 할 예정이다.

## Why S3?

참고 ) [https://www.justaftermidnight247.com/insights/ebs-efs-and-s3-when-to-use-awss-three-storage-solutions/](https://www.justaftermidnight247.com/insights/ebs-efs-and-s3-when-to-use-awss-three-storage-solutions/)

AWS 를 사용한다면 백업에 사용할 수 있는 기능으로 EBS. EFS, S3가 존재한다. EBS의 경우 단일 EC2에만 접근할 수 있기 때문에 확장성이 떨어져 처음부터 제외했다. EFS와 S3 사이에서 고민을 해보았는데, 비용성 면에서 S3를 택하였다. 우선 EFS를 사용한다면, 큰 장점은 우선 디렉토리 마운트로 실시간으로 백업이 가능하다는 것이다. 중요 파일들은 github, gitlab에 남아있기 때문이다. 다만, 젠킨스의 master 파일의 경우 실시간으로 계속 백업을 진행할 필요가 있을까 하는 고민을 하였다. 가장 중요한 플러그인 정보, 설정 정보, CI 관련 정보는 실시간 백업 필요성을 느끼지 못하였다. EFS 는 어쩔 수 없이 인스턴스가 EFS에 대한 엑세스 처리량이 많아지기 때문이 비용이 S3보다 많아질 수 밖에 없다. 이러한 이유로, 백업용으로 S3를 택하였다.

## How Back Up?

참고 ) [https://medium.com/@bennirus/automated-daily-backups-of-jenkins-master-to-amazon-s3-bucket-1ba6e875c0f0](https://medium.com/@bennirus/automated-daily-backups-of-jenkins-master-to-amazon-s3-bucket-1ba6e875c0f0)

![image](https://user-images.githubusercontent.com/93571332/203681986-3df522e1-b848-4137-9b15-7eac1639591a.png)

1. Jenkins 주요 설정이 담긴 폴더를 tar 로 압축하고 S3에 업로드
2. 자정에 백업이 실행되도록 설정

## Back Up Setting

### ****Download AWS CLI to EC2 Instance****

```bash
# jenkins의 경우 docker conatiner로 설치되어 있기 때문에 먼저 container 안으로 접속
$ docker exec -it jenkins /bin/bash
$ apt-get install awscli
$ aws --version
aws-cli/1.19.1 Python/3.9.2 Linux/5.15.0-1019-aws botocore/1.20.0
```

### ****Create S3 Bucket****

In your AWS account navigate to S3 and create a new bucket.

![image](https://user-images.githubusercontent.com/93571332/203682012-73dd5311-0159-4c3b-9ecc-f1a80a60ba1e.png)

### ****Create IAM User****

For us to be able to upload to S3 we will need an IAM user.

![image](https://user-images.githubusercontent.com/93571332/203682042-2534879b-c828-4f7d-bb31-20130b3e8955.png)

![image](https://user-images.githubusercontent.com/93571332/203682071-6da8318f-5576-4061-aece-1c91f76efd41.png)

### ****Configure Jenkins Environment Variables and Job****

Lets add our environment variables to our Global properties so that we can upload to our S3 bucket.

![image](https://user-images.githubusercontent.com/93571332/203682099-57aa9396-8366-4393-81aa-b7ceb1d582bc.png)

Lets create a new Jenkins job.

Build Triggers > Build Periodically

자정에 백업이 되도록 설정

![image](https://user-images.githubusercontent.com/93571332/203682146-48031aa5-0fe7-416a-847f-5abdf17be334.png)

Build > Execute Shell

tar gzip the ‘jenkins_home’ directory.

push our tar file to S3 bucket.

remove all files after successful upload.

![image](https://user-images.githubusercontent.com/93571332/203682193-d3bb5a4f-c873-45dc-8bfe-c7d1c2112df1.png)

### Back Up Check

![image](https://user-images.githubusercontent.com/93571332/203682231-3eac8b33-624f-447c-8ee9-fa7f89abb4c8.png)

![image](https://user-images.githubusercontent.com/93571332/203682266-0ad44327-c01e-44d0-8525-b3559bd05198.png)

```bash
# 아래의 경로에 대한 정보가 백업이 완료되었다
$ echo $JENKINS_HOME
/var/jenkins_home

$ aws s3 ls jenkinsbackupyujin
2022-11-24 02:17:01  400353280 jenkins_backup.tar
```
