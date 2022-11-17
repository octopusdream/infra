
# GOAL

>
Prometheus 를 AWS EC2 k8s cluster 환경에 배포한다. (EKS에서의 배포와 다르다)

## README 구성
1. EFS CSI Driver를 사용하기 위한 IAM 권한 설정을 해준다.
2. EFS, EFS CSI Driver 설치
3. EFS Mount, pv,pvc 작동 확인
4. prometheus 배포
5. 배포과정에서 발생하는 prometheus-server pod STATUS == CrashLoopBackOff 해결

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

## EFS 생성
1. EFS Mount는 DNS를 사용하기 때문에 위치한 VPC의 DNS 활성화를 해줘야한다. 또한 같은 VPC에 EFS를 생성해야 한다.
![](https://velog.velcdn.com/images/hyunshoon/post/ff857e89-f39d-49c9-bc54-62428976b5b3/image.png)

2. EFS 파일시스템 전용 보안그룹이 필요하다.

인바운드 프로토콜은 NFS로하고, 연결할 EC2 인스턴스의 VPC와 보안그룹에 맞게 설정한다.

EFS -> 세부정보 -> 연결

![](https://velog.velcdn.com/images/hyunshoon/post/a0484ecb-b3bf-4b63-9fdc-20d3175e10fb/image.png)


## EFS Client 설치 및 mount 
EFS 헬퍼를 사용하려면 amazon-efs-utils 패키지를 설치해야한다.

```
sudo apt-get update
sudo apt-get -y install git binutils
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
```


```
#마운트 할 폴더 생성
mkdir /efs
#마운트
sudo mount -t efs -o tls "file-system-id":/ /efs
#확인
df-h

```
![](https://velog.velcdn.com/images/hyunshoon/post/d7b7ec1f-0345-4800-897e-a1ca1ee71d46/image.png)
```
#재부팅후에도 마운트 유지 설정
vi /etc/fstab
"file-system-id":/ "efs-mount-point" efs _netdev,tls 0 0
```

## EFS CSI Driver 배포

helm을 사용한 배포

```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade --install aws-efs-csi-driver --namespace kube-system aws-efs-csi-driver/aws-efs-csi-driver --set useFips=true #FIPS 적용
```

`kubectl get pod -n kube-system`으로 확인
![](https://velog.velcdn.com/images/hyunshoon/post/5d375658-02a2-40fe-a947-4d4937a58458/image.png)

```

 ✘ ⚡ root@master  ~  k describe pod efs-csi-controller-76bdf5fd59-qc644 -n kube-system

Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m48s  default-scheduler  Successfully assigned kube-system/efs-csi-controller-76bdf5fd59-qc644 to worker1
  Normal  Pulling    3m47s  kubelet            Pulling image "amazon/aws-efs-csi-driver:v1.4.5"
  Normal  Pulled     3m14s  kubelet            Successfully pulled image "amazon/aws-efs-csi-driver:v1.4.5" in 33.272712306s
  Normal  Created    3m14s  kubelet            Created container efs-plugin
  Normal  Started    3m13s  kubelet            Started container efs-plugin
  Normal  Pulling    3m13s  kubelet            Pulling image "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner:v2.1.1-eks-1-18-13"
  Normal  Pulled     3m3s   kubelet            Successfully pulled image "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner:v2.1.1-eks-1-18-13" in 10.558849166s
  Normal  Created    3m2s   kubelet            Created container csi-provisioner
  Normal  Started    3m2s   kubelet            Started container csi-provisioner
  Normal  Pulling    3m2s   kubelet            Pulling image "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe:v2.2.0-eks-1-18-13"
  Normal  Pulled     2m55s  kubelet            Successfully pulled image "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe:v2.2.0-eks-1-18-13" in 6.635035635s
```
worker1에서는 정상 배포
시간이 지나보니 efs-csi-driver-controller가 deploy 2개 모두 worker1에 배포되었다. 이게 문제가 될지 추후에 알아보겠다.

## pv, pvc test on EFS using CSI Driver

pv.yaml
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-server
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: efs.csi.aws.com
    volumeHandle: [FileSystemId] 
```
pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-server
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 10Gi
```
pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
  - name: app
    image: centos
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim
```

```
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml

kubectl get pods
 ✘ ⚡ root@master  ~/prometheus  kubectl exec -ti efs-app -- tail -f /data/out.txt
Tue Nov 15 04:06:27 UTC 2022
Tue Nov 15 04:06:32 UTC 2022
Tue Nov 15 04:06:37 UTC 2022
Tue Nov 15 04:06:42 UTC 2022
Tue Nov 15 04:06:47 UTC 2022
Tue Nov 15 04:06:52 UTC 2022
Tue Nov 15 04:06:57 UTC 2022
Tue Nov 15 04:07:02 UTC 2022
Tue Nov 15 04:07:07 UTC 2022
Tue Nov 15 04:07:12 UTC 2022
```

pv, pvc가 정상적으로 작동한다.

## helm chart 수정 후 프로메테우스 배포

helm을 사용하여 prometheus를 배포한다. 이 때, 앞에서 만든 pv,pvc를 prometheus-server에 연결해줘야 하므로 helm chart를 수정해야한다. 

```
helm fetch prometheus-community/prometheus
tar zvxf prometheus-15.18.0.tgz
```
value.yaml을 알맞게 수정

```
k apply -f pv.yaml
k apply -f pvc.yaml
helm install prometheus ./prometheus
```

![](https://velog.velcdn.com/images/hyunshoon/post/7281c81c-3b7a-4215-b472-2d8c52738da0/image.png)


## 🤦‍♂️prometheus-server STATUS == CrashLoopBackOff 

### Kubernetes CrashLoopBackOFF 란?

CrashLoopBackOff는 Kubernetes에서 첫 번째 컨테이너를 실행할 때 발생할 수 있는 일반적인 오류이다. 포드가 시작되지 못했고, Kubernetes가 포드를 다시 시작하려고 시도했으며, 계속해서 실패했음을 나타낸다.

기본적으로 포드는 항상 restart 정책을 실행한다. 즉, 실패 시 항상 restart 한다. 포드 템플릿에 정의된 restart 정책에 따라 Kubernetes가 포드를 여러 번 다시 시작하려고 할 수 있다.

포드가 다시 시작될 때마다 쿠버네티스는 "백오프 지연"으로 알려진 더 길고 긴 시간을 기다린다. 이 프로세스 중에 Kubernetes는 CrashLoopBackOff 오류를 표시한다.

![](https://velog.velcdn.com/images/hyunshoon/post/5dc6f50e-fe22-4e75-90ba-46107468d2b3/image.png)

### 첫 번째 시도 resource insufficient

worker1,2 의 available disk를 확인해보니 1.3, 1.4 Gi 였다. 각 볼륨을 8 -> 30으로 늘려서 사용해본다.

그래도 변화 없다.

### 두 번재 시도 container log

```shell
 ⚡ root@master  /etc  k logs prometheus-server-5d4d6d64f4-82wj4 -c prometheus-server-configmap-reload
2022/11/16 01:48:21 Watching directory: "/etc/config"
 ⚡ root@master  /etc  k logs prometheus-server-5d4d6d64f4-82wj4 -c prometheus-server
level=info ts=2022-11-16T01:59:15.551Z caller=main.go:337 msg="Starting Prometheus" version="(version=2.19.0, branch=HEAD, revision=5d7e3e970602c755855340cb190a972cebdd2ebf)"
level=info ts=2022-11-16T01:59:15.551Z caller=main.go:338 build_context="(go=go1.14.4, user=root@d4cf5c7e268d, date=20200609-10:29:59)"
level=info ts=2022-11-16T01:59:15.551Z caller=main.go:339 host_details="(Linux 5.15.0-1022-aws #26-Ubuntu SMP Thu Oct 13 12:59:25 UTC 2022 x86_64 prometheus-server-5d4d6d64f4-82wj4 (none))"
level=info ts=2022-11-16T01:59:15.551Z caller=main.go:340 fd_limits="(soft=1048576, hard=1048576)"
level=info ts=2022-11-16T01:59:15.551Z caller=main.go:341 vm_limits="(soft=unlimited, hard=unlimited)"
level=error ts=2022-11-16T01:59:15.554Z caller=query_logger.go:87 component=activeQueryTracker msg="Error opening query log file" file=/efs/prometheus/server/queries.active err="open /efs/prometheus/server/queries.active: permission denied"
panic: Unable to create mmap-ed active query log
```
prometheus-server-configmap-reload 는 특별한 점이 없다.
prometheus-server 는 err="open /efs/prometheus/server/queries.active: permission denied" 에러가 뜬다. 이 문제 때문에 crushLoopBackOff가 발생하는지는 모르겠지만 일단 해결해본다.

`chown 1000:1000 /efs/prometheus/server
`

해결되지 않는다.

### 세 번째 시도 Persistent Volume securityContext

configuration 파일에서 runAsUser 필드는 포드의 컨테이너에 대해 모든 프로세스가 runAsUser에 명시된 user ID로 실행되도록 지정한다.

runAsGroup 필드는 포드 컨테이너 내의 모든 프로세스에 대한 기본 group ID를 지정한다. 이 필드를 생략하면 컨테이너의 기본 그룹 ID는 0 이 된다.

runAsGroup 이 지정된 경우 생성된 모든 파일은 runAsUser와 runAsGroup에 의해 소유된다.

fsGroup 필드가 지정되면 컨테이너의 모든 프로세스도 보조 그룹 fsGroup ID의 일부가 된다. 볼륨 및 해당 볼륨에 생성된 모든 파일의 소유자는 fsGroup이 된다.


helm으로 설치한 values.yaml 파일의 securityContext는 다음과 같다.

![](https://velog.velcdn.com/images/hyunshoon/post/e58abb18-6684-4227-8eba-84b6f241c754/image.png)

runAsUser, runAsGroup, fsGroup을 모드 0(root)로 바꿔준다.

`Error: container's runAsUser breaks non-root policy (pod: "prometheus-server-7b46689765-z6l7s_default(eb37467d-04b4-4480-9fdf-37a2119f3b6c)", container: prometheus-server)
`
container의 runAsUser는 루트로 하면 안된다. 따라서 1000으로 바꿔준다.

마찬가지로 해결되지 않는다.

### 네 번째 시도 Persistent Volume Access Mode

ReadWriteOnce

the volume can be mounted as read-write by a single node. ReadWriteOnce access mode still can allow multiple pods to access the volume when the pods are running on the same node.

ReadOnlyMany

the volume can be mounted as read-only by many nodes.

ReadWriteMany

the volume can be mounted as read-write by many nodes.

ReadWriteOncePod

the volume can be mounted as read-write by a single Pod. Use ReadWriteOncePod access mode if you want to ensure that only one pod across whole cluster can read that PVC or write to it. This is only supported for CSI volumes and Kubernetes version 1.22+.

pv.yaml, pvc.yaml ReadWriteOnce -> ReadWriteMany로 변경

마찬가지로 안된다.

### 다섯 번째 시도 Instance-Profile Check

이전에 만든 role과 policy는 확인했을 때 EFS에 대한 엑세스가 맞게 되어있는 것 같다.

모든 노드에 인스턴스 프로필을 생성하고 그 인스턴스 프로필이 권한이 있는 것인데 어떻게 연결해주는건지 다시 확인할 필요성을 느꼈다.

```
 ⚡ root@master  ~/prometheus  aws ec2 describe-iam-instance-profile-associations
```
연결되어있지 않았다... 😂
```
#인스턴스프로필 list 확인
aws iam list-instance-profiles

aws ec2 associate-iam-instance-profile --iam-instance-profile Name="" --instance-id "" 로 연결. 세 가지 프로필 모두 연결해주면 된다.

aws ec2 describe-iam-instance-profile-associations 로 확인 가능하다
```

인스턴스 프로필 연결후에도 마찬가지로 에러가 해결되지 않는다.

### 여섯 번째 시도 코드 뜯어보기

Go라서 봐도 모르겠으니 일단 넘어간다.

### 일곱 번째 시도 prometheus remote storage Intergration 확인

원격 스토리지 결합에 추가 설정이 있을 수 있다.

프로메테우스의 로컬 스토리지는 단일 노드의 확장성과 내구성에 한계가 있다. 프로메테우스 자체에서 클러스터된 스토리지를 해결하려고 시도하는 대신 프로메테우스는 원격 스토리지 시스템과 통합할 수 있는 인터페이스를 제공한다.

![](https://velog.velcdn.com/images/hyunshoon/post/d82d96bc-61f3-4284-8bc4-16180338d83a/image.png)

프로메테우스는 세 가지 방식으로 원격 스토리지 시스템과 동합된다.

1. 표준화된 형식으로 원격 URL에 수집하는 샘플을 작성할 수 있다.
2. 다른 프로메테우스 서버에서 표준화된 형식으로 샘플을 수신할 수 있다.
3. 표준화된 형식으로 원격 URL에서 샘플 데이터를 읽을 수 있다.

프로메테우스에서 원격 스토리지 통합을 구성하는 방법에 대한 자세한 내용은 프로메테우스 구성설명서의 원격 쓰기 및 원격 읽기 섹션을 참조.

하지만, 온프레미스 환경에서 NFS-server를 사용한 remote storage 연결이 된 점을 생각해보면 이 부분은 helm 으로 설치하는 과정에서 제대로 설정되어있을 수 있다. 물론, EFS 를 사용할 때 다를 수 있지만 알아보는 우선순위를 미룬다. 

### 여덟 번째 방법 AWS - Prometheus 호환 확인

추가적인 설정이 필요할 수 있다.

### 아홉 번째 방법 aws-csi-driver-controller

현재 worker1 에만 aws-csi-driver-controller pod가 2대 띄워져있다. 이게 문제가 되는지 알아본다.

### 마지막 방법 prometheus hardway

helm 으로 설치하니 어떻게 구성되어있는지 몰라 디버깅이 어렵다. 수동으로 직접 설치해본다.

## 해결

If a parent directory has no execute permission for some user, then that user cannot stat any subdirectories regardless of the permissions on those subdirectories.

세 번째 해결 방법에서 Persisten Volume securityContext를 수정해주고,
`chown 1000:1000 /efs/prometheus/server` 를 해주었다. 하지만 해결되지 않았는데 위의 코멘트 처럼 상위 디렉토리에는 권한이 없기 때문이다.

`chown 1000:1000 /efs` 를 해주니 해결 되었다.

배포는 values.yaml 을 직접 수정하지않고 아래 방법으로 한다.

```
 ✘ ⚡ root@master  ~/prometheus 
helm install prometheus prometheus-community/prometheus \
--set pushgateway.enabled=True \
--set alertmanager.enabled=True \
--set nodeExporter.tolerations[0].key=node-role.kubernetes.io/master \
--set nodeExporter.tolerations[0].operator=Exists \
--set nodeExporter.tolerations[0].effect=NoSchedule \
--set server.persistentVolume.existingClaim="prometheus-server" \
--set server.securityContext.runAsGroup=1000 \
--set server.securityContext.runAsUser=1000 \
--set server.service.type="LoadBalancer" \
--set server.storage.tsdb.path="/efs/perometheus/server"
```

Reference

- https://minjii-ya.tistory.com/30 : EFS 파일 시스템-생성/마운트
- https://docs.aws.amazon.com/ko_kr/efs/latest/ug/installing-amazon-efs-utils.html#installing-other-distro : 아마존 EFS Client 수동 설치
- https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-persistent-storage/ : AWS에서 영구 스토리지를 사용하려면?
- https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-files.html : aws configure 설정
- https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html: 인스턴스 프로필 사용
- https://github.com/kubernetes-sigs/aws-efs-csi-driver: aws-efs-csi-driver github repo
- https://devlog-wjdrbs96.tistory.com/302: IAM 개념 및 용어 정리
- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html
- https://helm.sh/ko/docs/intro/using_helm/: helm
- https://komodor.com/learn/how-to-fix-crashloopbackoff-kubernetes-error/: crashLoopbackoff
- https://kubernetes.io/ko/docs/concepts/configuration/configmap/#configmap-immutable : 쿠버네티스 컨피그맵
- https://github.com/prometheus/prometheus/issues/5976 : panic err 
- https://kubernetes.io/docs/concepts/storage/persistent-volumes/ : persistent-volume
- https://prometheus.io/docs/prometheus/2.37/storage/#overview: 프로메테우스 스토리지
- https://askubuntu.com/questions/812513/permission-denied-in-777-folder: 리눅스 권한 설정
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/: 파드-컨테이너 security-context
