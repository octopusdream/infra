
# GOAL

>
Prometheus 를 AWS EC2 k8s cluster 환경에 배포한다. (EKS에서의 배포와 다르다)

## Process
1. EFS CSI Driver를 사용하기 위한 IAM 권한 설정을 해준다.
2. EFS, EFS CSI Driver 설치
3. EFS Mount, pv,pvc 작동 확인
4. prometheus 배포

# EFS를 쓰는 이유

![](https://velog.velcdn.com/images/hyunshoon/post/c074d50c-5667-49e6-a02f-e5b8238c9dce/image.png)


Master node(EC2)에 NFS-server를 구성하고 Worker node들에 NFS-utils를 구성해서 Mount하여 사용할 수 있다. 훨씬 간편하지만, Master node가 죽는경우 스토리지 또한 죽는다. 또한, 다중 가용영역에 쿠버네티스 클러스터를 배포하였을 때, storage가 Zone에 종속적이게 된다면 고가용성 측면에서 취약한 문제도 있다. 따라서, Zone이 아닌 Region에 의존적인 AWS EFS를 사용한다. (EBS는 Zone에 의존적)

## Prometheus Storage 짧게 설명

프로메테우스는 로컬 온디스크 tsdb를 제공하지만, 선택적으로 원격 저장소와 통합할 수 있다.

프로메테우스의 로컬 스토리지는 단일 노드의 확장성과 내구성으로 제한된다. Prometheus 자체에서 클러스터된 스토리지를 해결하려고 하는 대신 Prometheus는 원격 스토리지 시스템과 통합할 수 있는 인터페이스 세트를 제공한다.

# 들어가기에 앞서 문제 상황

처음으로는 마스터 노드를 NFS-server로 빠르게 만들고 테스트하려고 했다. 하지만, 이 부분도 시행착오가 있었는데, EC2 인스턴스를 생성할 때 기본이 되는 EBS 디스크 용량이 8G 였다는 점이다. pv,pvc request storage capacity가 사용가능한 용량을 넘어섰고, prometheus-server pod는 pending 상태에 교착되었다. pv,pvc가 pending 상태였기 때문이고 이는 앞서 말한 스토리지 용량 부족에서 기인했다.

EBS volume 용량을 늘렸지만, Ready 상태에 도달하지는 못했다. prometheus-server Pod는 Pending -> Container Creating 상태로 바뀌었다. AWS 쿠버네티스 클러스터에서 영구 볼륨을 사용하려면 CSI(Container Storage Interface) Driver가 있어야 한다는걸 [AWS 공식문서](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html) 를 통해 알게 되었다. 이전에는 EBS-Provisoner를 사용했지만, 현재 EBS는 [쿠버네티스 공식 문서](https://kubernetes.io/docs/concepts/storage/volumes/#awselasticblockstore)에 따르면 지원하지 않는다.
![](https://velog.velcdn.com/images/hyunshoon/post/31924675-b3b4-4cbf-abd1-93fb104b28eb/image.png)
EFS-provisoner 또한 아래에 포함된다.
![](https://velog.velcdn.com/images/hyunshoon/post/d33417a6-4a66-4657-92b6-ff3adc4c9e3f/image.png)


따라서, **EFS CSI 드라이버를 사용하는 방법으로 진행한다.**

[AWS EFS CSI 드라이버](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html)설치 문서를 보며 따라했는데... 알고보니 EKS 서비스를 사용해야만 할 수 있는 방법이었다. EC2에서 설치하는 방법은 [AWS-EFS-CSI-Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)에 설명되어있다.

해당 포스팅은 위 Repo를 기반으로 EFS를 마운트한다.

# AWS EFS CSI Driver란?

AWS EFS CSI 드라이버는 컨테이너 오케스트레이터가 AWS EFS 파일 시스템의 라이프사이클을 관리할 수 있도록 CSI specification을 구현한다.

EFS CSI 드라이버는 동적 프로비저닝과 정적 프로비저닝을 지원한다. 현재 동적 프로비저닝은 각 PV에 대한 엑세스 포인트를 생성한다. 즉, AWS EFS 파일 시스템은 먼저 AWS에서 생성되어야 하며 스토리지 클래스 매개변수에 대한 입력으로 제공되어야 한다. 먼저, 정적 프로비저닝을 위해서는  AWS EFS 파일시스템이 생성되어야한다. 그 후 드라이버를 사용하여 컨테이너 내부에 볼륨으로써 마운트 될 수 있다.


# EFS CSI Driver on Kubernetes (IAM 권한 설정)

**Set up driver permission:**
드라이버는 유저를 대신하여 볼륨을 관리하기위해 AWS EFS와 통신하려면 IAM 퍼미션이 필요하다. 드라이버에 IAM 권한을 부여하는 방법은 여러가지가 있다.


1. Using IAM Role for Service Account (Recommended if you're using EKS): create an IAM Role for service accounts with the required permissions. Uncomment annotations and put the IAM role ARN in service-account manifest

2. **Using IAM instance profile - grant all the worker nodes with required permissions by attaching policy to the instance profile of the worker.
IAM 인스턴스 프로필 사용 - worker node의 인스턴스 프로필에 정책을 연결하여 모든 worker node에 필요한 권한을 부여
** 

EC2이므로 2번 방법을 선택한다.

## IAM 개념 정리 (instance-profile vs user vs role vs policy)

참고사항이지만 필수적으로 알아야 한다.

### IAM 정책이란?
권한들의 모음이다. 사용자나 그룹들에 권한을 직접 적용할 수는 없고 권한들로 만든 정책을 적용해야 한다. 정책은 사용자, 그룹 역할에 적용할 수 있다. 

### 인스턴스 프로파일 이란?

사용자가 사람을 구분하고 그 사람에 권한을 주기 위한 개념이었다면 인스턴스 프로파일은 EC2 인스턴스를 구분하고 그 **인스턴스에 권한을 주기 위한 개념**이다. 인스턴스 프로파일은 역할을 위한 컨테이너로서 인스턴스 시작 시 EC2 인스턴스에 역할 정보를 전달하는 데 사용한다. 

즉, 인스턴스 프로파일이 지정된 EC2는 시작 시 역할 정보를 받아오고 해당 역할로 필요한 권한들을 얻게 된다.

### IAM 역할이란?

어떤 행위를 하는 객체에 여러 정책을 적용한다는 점에서 사용자와 비슷하지만 객체가 사용자가 아닌 서비스나 다른 AWS 계정의 사용자라는 점에서 차이가 있다.

보통은 사용자가 아닌 특정 서비스에서 생성한 객체에 권한을 부여하는 데 사용한다.(ex: EC2, S3, CodeDeploy에 역할을 부여하기)

예를들어, 우리가 만들어서 사용하는 EC2 인스턴스가 S3에서 파일을 읽어오려면 S3 파일을 읽을 수 있는 권한으로 정책을 만든 뒤에 해당 정책으로 역할을 만들어 EC2 인스턴스에 지정을 해주어야한다.


## IAM 설정


EC2 인스턴스에서 생성한 인스턴스 프로필에 직접적으로 정책 연결은 할 수 없다.
![](https://velog.velcdn.com/images/hyunshoon/post/6de5098d-a486-4b6b-affa-a0d7ae1c7b99/image.png)

[인스턴스 프로필 메뉴얼](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)

정책은 group, user, role에만 직접 연결이 가능하다.

따라서, 우리는 **1. 역할을 만들고 2. 역할에 정책을 연결한 후에 3. 생성한 인스턴스 프로필에 add-role-to-instance-profile을 해주고 4. instance-profile을 instance에 연결하면 된다.**

그 전에 AWS CLI 환경 사용을 위한 구성이 필요하다.

0. aws cli 설치

```
apt-get install unzip zip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
설치완료


0.  aws configure 설정

cli 설치한다고 끝이 아니다. credentials이 없으므로 aws configure 설정을 IAM 정보를 기반으로 해준다.

[AWS 홈페이지](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config) 참고해서 최종적으로 아래 예시와 같이 설정하면 된다. (액세스키를 발급받아야 한다.)

```
$ aws configure
AWS Access Key ID [None]: **************LE
AWS Secret Access Key [None]: ***************************EY
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

1. 인스턴스 역할 생성

- ec2-role-trust-policy.json 파일 생성
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```
- for_efs_role 역할 생성
```
aws iam create-role \
    --role-name for_efs_role \
    --assume-role-policy-document file://ec2-role-trust-policy.json
```

2. 생성한 역할을 정책에 연결

- 정책 생성 (EFS github repo)

```
#repo에서 정책 다운로드
wget https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
#정책 생성
aws iam create-policy --policy-name ec2_kubernetes --policy-document file://iam-policy-example.json
```

- 역할에 정책 연결

`aws iam list-policies`로 정책 조회 가능
```
aws iam attach-role-policy --role-name for_efs_role --policy-arn arn:aws:iam::"id":policy/ec2_kubernetes
```

3. 인스턴스 프로필에 역할 추가


- 모든 인스턴스에 인스턴스 프로필생성

```
aws iam create-instance-profile --instance-profile-name for_efs_instance_profile
aws iam create-instance-profile --instance-profile-name for_efs_instance_profile_worker1
aws iam create-instance-profile --instance-profile-name for_efs_instance_profile_worker2
```
- output
```
{
    "InstanceProfile": {
        "Path": "/",
        "InstanceProfileName": "for_efs_instance_profile",
        "InstanceProfileId": "Id",
        "Arn": "arn",
        "CreateDate": "2022-11-15T01:23:39+00:00",
        "Roles": []
    }
}

```

- 생성된 인스턴스 프로필에 역할(aws iam role-list 로 확인) 연결

```
add-role-to-instance-profile --instance-profile-name "profile-name" --role-name "role-name"
aws iam add-role-to-instance-profile --instance-profile-name for_efs_instance_profile --role-name for_efs_role
aws iam add-role-to-instance-profile --instance-profile-name for_efs_instance_profile_worker1 --role-name for_efs_role
aws iam add-role-to-instance-profile --instance-profile-name for_efs_instance_profile_worker2 --role-name for_efs_role
```

최종 확인: `aws iam list-instance-profiles`으로 모든 인스턴스 프로필이 정상적으로 생성되었는지 확인한다.

4. 인스턴스에 인스턴스 프로필 연결

```
#연결. 세 가지 프로필 모두 연결해야 한다.
aws ec2 associate-iam-instance-profile --iam-instance-profile Name="" --instance-id "" 
#확인
aws ec2 describe-iam-instance-profile-associations
```

Reference

- https://minjii-ya.tistory.com/30 : EFS 파일 시스템 -생성/마운트
- https://docs.aws.amazon.com/ko_kr/efs/latest/ug/installing-amazon-efs-utils.html#installing-other-distro : 아마존 EFS Client 수동 설치
- https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-persistent-storage/ : AWS에서 영구 스토리지를 사용하려면?
- https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-files.html : aws configure 설정
- https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html: 인스턴스 프로필 사용
- https://github.com/kubernetes-sigs/aws-efs-csi-driver: aws-efs-csi-driver github repo
- https://devlog-wjdrbs96.tistory.com/302: IAM 개념 및 용어 정리
