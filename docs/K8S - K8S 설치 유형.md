k8s는 용도에 따라서 사용하는 k8s 설치 툴의 종류가 달라진다.
 
### 개발 용도의 쿠버네티스 설치	  
  - Minikube
  - Docker for Mac / Windows에 내장된 쿠버네티스
  
### 서비스 테스트 또는 운영 용도의 쿠버네티스 설치	  
  - kops
  - kubespray
  - kubeadm
  - EKS, GKE, AKS 등의 관리형 서비스
---
### kops(Kubernetes Operation)
![image](https://user-images.githubusercontent.com/88362207/202084095-34e726ea-a12e-4974-bf50-1d97d18e99e3.png)

kops는 클라우드 플랫폼에서 쉽게 쿠버네티스 클러스터를 생성 및 관리를 쉽게 하도록 도와주는 오픈소스 툴이다. 

kubeadm은 직접 서버와 네트워크 인프라를 구축하여 그 위에서 k8s를 설치 및 운영 하지만 kops는 서버 인스턴스와 네트워크 서비스 등을 클라우드 환경에서 자동으로 생성하고 그 위에 k8s까지 설치한다.                              

kops는 프로덕션 레벨의 쿠버네티스 클러스터를 간단한 CLI 명령을 통해 생성, 관리, 업그리에드, 삭제할 수 있도록 지원한다.

쿠버네티스 클러스터의 마스터노드 HA구성 등 다양한 옵션을 간단한 명령어로 쉽게 설정할 수 있으며, Terraform을 통해 프로비저닝할 수있다.

kops는 현재 2022년 11월 16일 기준, AWS, GCP는 오피셜하게 지원하며, DigitalOcean, Openstack은 베타지원 , Azure는 알파지원을 하고 있다. 


### AWS IAM계정 및 권한

- kops로 쿠버네티스를 설치하고 관리하기 위해서는 다음과 같은 5개의 권한이 필요하다.
```
AmazonEC2FullAccess
AmazonRoute53FullAccess
AmazonS3FullAccess
IAMFullAccess
AmazonVPCFullAccess
```

### 쿠버네티스 구축 순서

- kops 및 kubectl 설치
- 쿠버네티스 클러스터 구축을 위한 환경설정
- kops를 활용한 쿠버네티스 클러스터 구축

설치 방법 https://kubernetes.io/ko/docs/setup/production-environment/tools/kops/


---
### kubespray
![image](https://user-images.githubusercontent.com/88362207/202102171-1e72225a-0976-44b5-b790-44567cbb4ca1.png)

kubespray는 Ansible을 통해 쿠버네티스 클러스터를 유연하고 쉽게 배포 및 관리하기 위한 강력한 오픈 소스 툴이다. 

AWS, GCP, Azure, OpenStack, vSphere, Packet(베어메탈), Oracle Cloud등 여러 플랫폼에서 클러스터를 배포할 수 있다. 

kubespray는 Ansible과 kubeadm의 조합을 활용하여 Linux OS 종류, 네트워크 플러그인, 애플리케이션 등 옵션을 선택하여 쿠버네티스를 배포한다.


설치 방법 https://kubernetes.io/ko/docs/setup/production-environment/tools/kubespray/

---
### kubeadm
![image](https://user-images.githubusercontent.com/88362207/202101742-cf183b61-b4d7-481e-9c97-246de39a67da.png)

kubeadm은 일반적인 서버 클러스터 환경에서도 쿠버네티스를 쉽게 설치할 수 있게 해주는 관리 툴이다.

kubeadm은 쿠버네티스에서 제공하는 기본적인 도구로, 이러한 클러스터를 빠르고 쉽게 구축하기 위한 다양한 기능을 제공한다.

kubeadm은 쿠버네티스 커뮤니티에서도 권장하는 설치 방법 중 하나이며, 쿠버네티스를 처음 시작하는 사람도 쉽게 쿠버네티스를 설치할 수 있다는 장점이 있다. 

kubeadm은 베어 리눅스, EC2 리눅스, VM 리눅스 등 인프라 환경에 상관없이 일반적인 리눅스 서버라면 모두 사용할 수 있다. 


설치 방법 https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

---
### EKS(AWS), GKE(GCP), AKS(Azure) 등의 관리형 서비스 (Public Cloud) 

AWS의 EKS, GCP의 GKE, Azure의 AKS 등의 관리형 서비스를 이용해 쿠버네티스를 사용하면 쿠버네티스의 설치 및 관리까지도 클라우드 제공자(AWS,GCP,Azure)가 담당하므로 쿠버네티스 관리 및 유지보수의 비용이 줄어들게 된다.

관리형 서비스를 사용하면 별도로 쿠버네티스를 설치할 필요 없이 실제 서비스 환경을 구성할 수 있다는 장점이 있다.


![image](https://user-images.githubusercontent.com/88362207/202118662-25a739d6-6063-4c37-aa34-2f427d046eda.png)

쿠버네티스 사용 환경에 대한 특징

설치 방법 https://kubernetes.io/ko/docs/setup/_print/#pg-00e1646f68aeb89f9722cf6f6cfcad94

---
### 결론
본 프로젝트에서 AWS EKS를 사용하면 되는데 굳이 kops, kubeadm, kubespray를 활용하여 AWS에 k8s 클러스터를 구축하는지 생각할 수 있다.

AWS에 직접 k8s 클러스터를 구축하는 이유 아래와 같다.

1. 프로젝트를 진행하면서, 쿠버네티스 EKS는 가격적(시간당 0.1USD)으로 부담이 많이 된다.
(마스터노드의 수는 Raft알고리즘 특성 상 홀수로 유지하는 것이 좋으며, 두 개의 마스터노드는 한개만도 못한 결과를 초래한다)

2. AWS에서 어떤 방식으로 쿠버네티스 클러스터가 구축되고, 동작을 하는지에 대해 이해하기 위해서 EKS, GKE같은 관리형 서비스를 사용하기 보다는 kubeadm을 사용하여 k8s 클러스터를 직접 구축 해보고 오브젝트 등 전체적인 개념을 파악해 보기 위함이다.


