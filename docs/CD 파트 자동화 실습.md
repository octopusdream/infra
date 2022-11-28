## 환경 설정

OS : Window 10

인스턴스 유형 (worker nodes) : t3.micro (x 6)

Public ip : 13.124.252.111

kubernetes version : 1.22

ArgoCD version : 2.0.3

## What EKS?

참고 ) [https://aws.amazon.com/ko/eks/](https://aws.amazon.com/ko/eks/)

본래 테스트에서는 EC2에 kubeadm 으로 쿠버네티스 클러스터 환경을 만들 예정이지만, 지금은 ArgoCD를 테스트 하기 위해 EKS 를 사용하여 간단하게 쿠버네티스 환경을 만들고자 한다.

Amazon EKS는 자체 Kubernetes 제어 영역이나 작업자 노드를 설치 및 운영할 필요 없이 AWS에서 Kubernetes를 손쉽게 실행할 수 있도록 지원하는 관리형 서비스이다.

AWS 상에 EKS 자체가 쿠버네티스 master 노드 역할을 하는 듯 한다.

## Install eksctl

아래는 윈도우 상에서의 eksctl 설치 방법이다.

![image](https://user-images.githubusercontent.com/93571332/204200963-cdcda2c8-06d1-40af-8765-57097b298087.png)

![image](https://user-images.githubusercontent.com/93571332/204200992-b77acfeb-17de-4200-a87c-274682838cd4.png)

![image](https://user-images.githubusercontent.com/93571332/204201004-26123753-a238-4ee2-a375-b45cd0f81415.png)

(vscode 오른쪽 마우스 → 관리자 권한으로 실행) 

![image](https://user-images.githubusercontent.com/93571332/204201024-f4b8b1da-4e60-44b8-baf1-5fe8b6a9ea2a.png)

```powershell
# ekctl 설치 준비 완료
PS C:\Users\yusin> Get-ExecutionPolicy
Restricted
PS C:\Users\yusin> Set-ExecutionPolicy AllSigned
PS C:\Users\yusin> Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
PS C:\Users\yusin> choco
Chocolatey v1.2.0
Please run 'choco -?' or 'choco <command> -?' for help menu.
```

![image](https://user-images.githubusercontent.com/93571332/204201071-465ec3c8-8644-451e-bd60-19411adcc40a.png)

```powershell
PS C:\Users\yusin> choco install -y eksctl
PS C:\Users\yusin> eksctl version
0.118.0
# aws configure 을 진행 이후 eksctl create cluster 명령어 가능
```

## Spin Our Very Frist EKS Cluster

```bash
root@ip-172-31-0-65:~/eksctl# eksctl create cluster --name eksctl-test --region ap-northeast-2 --nodegroup-name ng-default --node-type t3.small --nodes 2
```

### 에러 발생

‘kubectl not found, v1.10.0 or newer is required’

[https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html) 로 들어가서 직접 kubectl 을 다운로드함 (1.22 로 다운로드함)

### 확인

```bash
C:\Users\user\eksctl>kubectl get nodes
NAME                                               STATUS   ROLES    AGE   VERSION
ip-192-168-1-43.ap-northeast-2.compute.internal    Ready    <none>   16m   v1.23.13-eks-fb459a0 
ip-192-168-63-16.ap-northeast-2.compute.internal   Ready    <none>   16m   v1.23.13-eks-fb459a0
```

## ArgoCD Installation

참고 ) [https://argo-cd.readthedocs.io/en/stable/getting_started/](https://argo-cd.readthedocs.io/en/stable/getting_started/)

```bash
C:\Users\user\eksctl> kubectl create namespace argocd
namespace/argocd created

C:\Users\user\eksctl> kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

# window 에서의 명령어
C:\Users\user\eksctl> choco install argocd-cli 

# Loadbalancer 대신 Port Forwarding
C:\Users\user\eksctl> kubectl port-forward svc/argocd-server -n argocd 8080:443

# if Loadbalancer,
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Login Using The CLI
C:\Users\user\eksctl>kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
V3J2WnRYc3N0YkthVmRCQQ== --> WrvZtXsstbKaVdBA (base64 decode)
```

### 에러 발생 1

```bash
C:\Users\user\eksctl> kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     0/1     Pending   0          4m9s
argocd-applicationset-controller-57bfc6fdb8-gs82h   0/1     Pending   0          4m10s
argocd-dex-server-866c9bdd5b-tq2lq                  0/1     Pending   0          15m
argocd-notifications-controller-954b6b785-jdxnw     1/1     Running   0          15m
argocd-redis-547f5d94cd-42mfd                       0/1     Pending   0          4m10s
argocd-repo-server-d4db5c89d-jkspl                  0/1     Pending   0          4m9s
argocd-server-5b8c45c484-z8dh7                      1/1     Running   0          15m
```

describe 명령어를 사용하여 확인해보니 노드 당 올릴 수 있는 Pod 수를 초과한 것 같다.

노드를 더 추가해준다

```bash
[eksctl-create-ng.yaml]
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata: 
  name: eksctl-test
  region: ap-northeast-2

nodeGroups:
  - name: ng1-public
    instanceType: t3.small
    desiredCapacity: 2

managedNodeGroups:
  - name: ng2-managed
    instanceType: t3.small
    minSize: 1
    maxSize: 3
    desiredCapacity: 2

$ eksctl create nodegroup --config-file=eksctl-create-ng.yaml
```

### 확인

```bash
C:\Users\user\eksctl> kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0 
         44s
argocd-applicationset-controller-57bfc6fdb8-j9htc   1/1     Running   0 
         44s
argocd-dex-server-866c9bdd5b-tq2lq                  1/1     Running   0 
         134m
argocd-notifications-controller-954b6b785-jdxnw     1/1     Running   0 
         134m
argocd-redis-547f5d94cd-p5rv4                       1/1     Running   0 
         44s
argocd-repo-server-d4db5c89d-4k9xp                  1/1     Running   0 
         44s
argocd-server-5b8c45c484-z8dh7                      1/1     Running   0 
         134m
```

### 에러 발생 2

pod는 잘 배포되었으나 어째서인지 데이터를 가져오지 못하고 있다. 버전 충돌이 일어난 듯 싶어 다운 그레이드를 해주었다.

![image](https://user-images.githubusercontent.com/93571332/204201147-8fdbb8f2-6fb0-4d33-8a9f-480feff4cbc5.png)

kubernetes 를 1.22로 설치하였기에, 이에 호환되는 버전을 지정하여 argocd 를 설치해주었다.

```bash
# 본래 프로젝트에서는 k8s 가 1.21 이기에 2.0.3 버전을 다운받음
C:\Users\user\eksctl> kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.0.3/manifests/install.yaml
```

### 확인

![image](https://user-images.githubusercontent.com/93571332/204201172-b7385b9d-d36a-42b5-b803-f84e00b07fdd.png)

## ArgoCD App Setup

### Deployment.yaml

github의 k8s_gitops_test 레포지토리에 deployment.yaml 파일을 작성한다.

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: flaskdemo
  name: flaskdemo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flaskdemo
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: flaskdemo
    spec:
      containers:
      - image: 15.164.210.210:5001/flask_test:27
        name: flaskdemo
        resources: {}
status: {}
---
apiVersion: v1
kind: Service
metadata:
  name: lb-service
  labels:
    app: lb-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: flaskdemo
```

### **Creating Apps Via UI**

Application Name, Repository URL 을 제외하고는 기본 설정을 한다.

앱 생성 이후 Pod 배포.

![image](https://user-images.githubusercontent.com/93571332/204201207-407ea076-53dc-49b4-b610-5ee04e2d98be.png)

![image](https://user-images.githubusercontent.com/93571332/204201215-7bb792e5-2331-40f1-abba-3e0f48fd4f0d.png)

![image](https://user-images.githubusercontent.com/93571332/204201244-2946aece-8320-41e3-97fa-0d947f5cd2a2.png)

### 에러발생

참고 ) [https://dct-wonjung.tistory.com/entry/Docker-failed-control-process-exited-오류-해결](https://dct-wonjung.tistory.com/entry/Docker-failed-control-process-exited-%EC%98%A4%EB%A5%98-%ED%95%B4%EA%B2%B0)

이미지를 가져오는데 오류가 났다

![image](https://user-images.githubusercontent.com/93571332/204201266-799d7f7c-dc3d-4e49-bc01-d3c6ae81ff0f.png)

```bash
C:\Users\user\eksctl> kubectl get pods
NAME                        READY   STATUS             RESTARTS   AGE
flaskdemo-84c8dcfdb-4mv4b   0/1     ImagePullBackOff   0          8m7s  
flaskdemo-84c8dcfdb-d4js6   0/1     ImagePullBackOff   0          8m7s  
flaskdemo-84c8dcfdb-gwgt4   0/1     ImagePullBackOff   0          8m7s
```

사설 레지스트리 포트인 5001을 보안그룹에 추가 —> 그래도 error

![image](https://user-images.githubusercontent.com/93571332/204201365-824c5fb3-ca40-4ead-893f-3ed0432f6882.png)

worker 노드에 port 22 를 열어서 들어가 확인해본다.

```bash
[root@ip-192-168-32-204 ~]# systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: **failed** (Result: start-limit) since Fri 2022-11-25 07:53:46 UTC; 13min ago
     Docs: https://docs.docker.com
  Process: 31982 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock $OPTIONS $DOCKER_STORAGE_OPTIONS $DOCKER_ADD_RUNTIMES (code=exited, status=1/FAILURE)
  Process: 31973 ExecStartPre=/usr/libexec/docker/docker-setup-runtimes.sh (code=exited, status=0/SUCCESS)
  Process: 31960 ExecStartPre=/bin/mkdir -p /run/docker (code=exited, status=0/SUCCESS)
 Main PID: 31982 **(code=exited, status=1/FAILURE)**

Nov 25 07:53:44 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: docker.service failed.
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: docker.service holdoff time over, scheduling restart.
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: Stopped Docker Application Container Engine.
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: start request repeated too quickly for docker.service
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: **Failed to start Docker Application Container Engine.**
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: Unit docker.service entered failed state.
Nov 25 07:53:46 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: docker.service failed.
Nov 25 07:54:31 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: start request repeated too quickly for docker.service
Nov 25 07:54:31 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: **Failed to start Docker Application Container Engine.**
Nov 25 07:54:31 ip-192-168-32-204.ap-northeast-2.compute.internal systemd[1]: docker.service failed.
```

 비보안 접속 허용을 위한 구성을 모든 노드에 적용

```bash
$ vi /etc/docker/daemon.json
{
...
	"insecure-registries" : [ "13.124.252.111:5001" ],
...
}
```

도커가 빠르게 재시작되지 않게 설정

```bash
$ vi /lib/systemd/system/docker.service
Restart=always --> Restart=no
$ systemctl daemon-reload
$ systemctl restart docker
```

명령어 재실행

### 확인

![image](https://user-images.githubusercontent.com/93571332/204201396-c97a36c7-f700-495d-8092-a759e42777a6.png)

```bash
C:\Users\user\eksctl>  kubectl get pods  
NAME                        READY   STATUS    RESTARTS   AGE
flaskdemo-84c8dcfdb-4mv4b   1/1     Running   0          7h16m
flaskdemo-84c8dcfdb-7sffn   1/1     Running   0          6h26m
flaskdemo-84c8dcfdb-d4js6   1/1     Running   0          7h16m

C:\Users\user\eksctl> kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP
          PORT(S)        AGE
kubernetes   ClusterIP      10.100.0.1     <none>
          443/TCP        12h
lb-service   LoadBalancer   10.100.56.95   a23ffd0149e364e8eb880ee643daa576-1329519081.ap-northeast-2.elb.amazonaws.com   80:32565/TCP   7h16m
```

![image](https://user-images.githubusercontent.com/93571332/204201424-bceaa4bd-b714-45de-89e0-88971ebb177a.png)
