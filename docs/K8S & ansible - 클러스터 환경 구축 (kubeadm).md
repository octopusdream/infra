## **kubernetes** 클러스터 구성

- 링크
    
    [[Kubernetes] kubeadm으로 Kubernetes 클러스터 구축하기](https://velog.io/@koo8624/Kubernetes-AWS-EC2-%EC%9D%B8%EC%8A%A4%ED%84%B4%EC%8A%A4%EC%97%90-Kubernetes-%ED%81%B4%EB%9F%AC%EC%8A%A4%ED%84%B0-%EA%B5%AC%EC%B6%95%ED%95%98%EA%B8%B0)
    
    [AWS EC2에서 kubeadm으로 쿠버네티스 클러스터 만들기 - (2) 쿠버네티스 클러스터 구성 :: 조은우 개발 블로그](https://jonnung.dev/kubernetes/2020/03/07/create-kubernetes-cluster-using-kubeadm-on-aws-ec2-part2/)
    
---

### 환경 요구 사항

- deb/rpm 패키지를 지원하는 Linux OS. ex) `Ubuntu`, `CentOS`
- 2 CPU 코어, 2Gb 이상의 RAM 을 지원하는 머신
- 보안그룹
    
    kubernetes 컴포넌트(ex, `kubelet`, `kube-apiserver`) 간 통신을 위해 EC2 인스턴스와 연결된 `security group`에서 해당 포트를 허용해야 한다.
    
    - Master Node (control-plane)
        - `kube-apiserver`: 6443
        - `kubelet`: 10250
        - `etcd`: 2379, 2380
    - Worker Node
        - `kubelet`: 10250

---

### 환경 설정

- 방화벽 종료

```bash
systemctl stop ufw && systemctl disable ufw
```

- apt 패키지 업데이트 및 필수 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```

- [swap disable](https://serverfault.com/questions/881517/why-disable-swap-on-kubernetes)

```bash
sudo su # root 권한으로 실행
swapoff -a
echo 0 > /proc/sys/vm/swappiness
sed -e '/swap/ s/^#*/#/' -i /etc/fstab
```

- Docker 설정 변경 ( v1.22 이후 )
    
    Cgroup 은 프로세스에 할당된 리소스를 제한하는데 사용된다. `kubelet` 은 Cgroup driver로 `systemd` 을 기본 값(v1.22 이후) 으로 사용한다. 
    
    Docker 가 내부에서 직접적인 컨테이너 관리를 담당하는 runc는 cgroup driver로 `cgroupsfs` 한다. 하지만 Cgroup 관리자가 `cgroupsfs` 인 경우 리소스가 부족할 때 시스템이 불안정해지는 경우가 있다. 단일 Cgroup 관리자가 일관성 있게 리소스를 관리하도록 단순화 하는 것이 좋다고 한다.
    
    [쿠버네티스 공식 문서](https://kubernetes.io/ko/docs/setup/production-environment/#cgroup-%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B2%84) 에 자세히 설명되어 있다.
    
    [systemd vs cgroupfs](https://tech.kakao.com/2020/06/29/cgroup-driver/) 의 차이는 링크에 자세히 설명되어 있다.
    
    따라서, Docker 를 컨테이너 런타임으로 사용할 경우에는 Docker 의 cgroup driver 를 `systemd`
    으로 변경해야 한다.
    
    ```bash
    # Docker가 사용하는 Cgroup driver 확인하기
    docker info |grep Cgroup
    
    vi /lib/systemd/system/docker.service
    ExecStart=... # --exec-opt native.cgroupdriver=systemd 추가
    
    # 설정 적용
    systemctl daemon-reload
    systemctl restart docker
    
    # 확인
    docker info | grep "Cgroup Driver"
    ```
    
---

### Docker 설치

- 패키지 설치

```bash
# 1. 도커설치를 위한 GPG 키 다운로드
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 2. 도커 리파지토리 추가
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 3. docker-ce 버전 설치
sudo apt-get install -y docker-ce=5:20.10.17~3-0~ubuntu-$(lsb_release -cs)
```

- 확인

```bash
docker --version
```

---

### **kubeadm, kubelet 및 kubectl 설치**

- `kubeadm` : 클러스터 초기화 및 부스트래핑
- `kubelet` : 컨테이너 런타임 및 Pod 의 라이프사이클 관리
- `kubectl` : kubernetes `control-plane`과 통신하기 위한 클라이언트

```bash
# 1. 쿠버네티스를 설치를 위한 GPG 키 다운로드
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# 2. k8s 저장소 추가
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# 3. 저장소 업데이트
sudo apt-get update

# 4. k8s 1.21 버전 설치
sudo apt-get install -y kubelet=1.21.1-00 kubeadm=1.21.1-00 kubectl=1.21.1-00

# 5. 업그레이드로 인한 버전업 방지
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
```

- 확인

```bash
kubeadm version
kubectl version
kubelet version
```

---

### **kubernetes 클러스터 생성**

- master init

```bash
# master
kubeadm init —-pod-network-cidr=192.168.0.0/16
```

- `-pod-network-cidr`은 우리가 사용할 `[calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart)` 공식 문서와 동일하게 `192.168.0.0/16`을 사용
- `-upload-certs` 옵션을 추가하면 `control-plane`의 SSL 인증서가 kubernetes cluster에 secret으로 저장된다. 해당 secret은 2시간 후 자동으로 사라지지만, `kubeadm join` 명령어를 사용하여 새로운 `control-plane` 노드를 추가할 때, 번거롭게 인증서를 복사하지 않아도 되어 편리하다. 하나의 `control-plane` 노드만을 사용할 경우에는 해당 옵션을 추가하지 않아도 된다.
- `-control-plane-endpoint` 옵션은 여러 개의 `control-plane` 노드로 HA를 구성하는 경우에 사용한다. 값으로 `control-plane` 노드들 앞단에 위치한 로드 밸런서의 IP 주소 혹은 도메인 명을 입력한다.
- `-apiserver-cert-extra-sans` 옵션은 `control-plane` 노드가 외부에 위치한 경우 (ex, `AWS EC2`), 로컬 머신에서 kubernetes 클러스터의 API 서버에 접근하기 위해 필요하다. 해당 옵션은 SSL 인증서의 SAN에 IP, 도메인 명을 추가로 등록한다.

- 현재 사용자에게 클러스터 어드민 권한 부여

```bash
# master
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
```

- weave-net 네트워크 플러그인 설치

```bash
# master
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

- worker 노드 join 해주고 확인

```bash
# worker
kubeadm join 192.168.8.100:6443 --token 92772f.i...    # init 에서 출력된 토큰으로 join
```

- 확인

```bash
kubectl get no,ns
kubectl get pod -n kube-system
```

---

### error1

- port

```bash
kubectl get pod -n kube-system
The connection to the server 10.0.3.57:6443 was refused - did you specify the right host or port?

kubectl get pod -n kube-system
The connection to the server localhost:8080 was refused - did you specify the right host or port?

# swap off
sudo -i
sudo swapoff -a
exit

# kubelet restart
sudo systemctl restart kubelet.service

# 안됨
```

- 해결

<aside>
💡 최신 버전의 K8S 에서는 Docker 와 관련된 CRI 중에서 Dockerd 가 사라지고, Containerd 만 남았다. 따라서 K8S는 1.21 버전으로 설치해야 한다.

</aside>

---

### error2

- calico-node NotReady

```bash
root@master:/home/ubuntu# kubectl get pod -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
...
calico-node-flwwx                          0/1     Running   0          9m12s
calico-node-gstmb                          0/1     Running   0          9m12s
calico-node-q5g9p                          0/1     Running   0          9m12s
...
```

문제가 발생한 부분의 에러 메시지를 확인하면 아래와 같이 나온다.

```bash
kubectl describe pod calico-node-d5hzc -n kube-system
...
calico/node is not ready: BIRD is not ready: BGP not established with <node-ip>
```

- BIRD, BGP

BIRD `calico` 의 모듈 중 하나로, kubernetes의 모든 노드에서 실행되는 BGP 데몬이다.

BGP는 네트워크 상의 A지점에서 B지점으로 가는 최단 경로를 탐색하기 위해 라우터들이 주고받는 라우팅 정보를 정의한 프로토콜이다.

BIRD는 `calico`에서 노드 별로 네트워크 라우팅 정보를 갱신한다.

`calico`는 라우팅 옵션의 기본 값으로 `IP-in-IP` 프로토콜을 사용합니다. `IP-in-IP` 프로토콜은 기존의 IP 헤더에 터널의 IP 주소 정보가 포함된 Outer IP 헤더를 추가하여 터널링을 구현한 프로토콜로, `calico`는 이를 활용하여 `overlay` 네트워크를 구성합니다. calico는 내부적으로 목적지 팟이 위치한 노드를 찾기 위해 BGP 프로토콜이 활용됩니다.

따라서, BGP 피어링을 위해 179번 포트에 대한 방화벽 정책을 허용하여야 합니다.

→ 안됨

- 해결1

```
💡 calico 대신에 weave-net 사용한다.
```

[클러스터 네트워킹](https://kubernetes.io/ko/docs/concepts/cluster-administration/networking/)

[위브넷](https://www.weave.works/oss/net/)은 쿠버네티스 및 호스팅된 애플리케이션을 위한 탄력적이고 사용하기 쉬운 네트워크이다. 위브넷은 [CNI 플러그인](https://www.weave.works/docs/net/latest/cni-plugin/) 또는 독립형으로 실행된다. 두 버전에서, 실행하기 위해 구성이나 추가 코드가 필요하지 않으며, 두 경우 모두, 쿠버네티스의 표준과 같이 네트워크에서 파드별로 하나의 IP 주소를 제공한다.

- 해결2
[calico 설치](https://projectcalico.docs.tigera.io/getting-started/kubernetes/self-managed-onprem/onpremises)
```
💡 클러스터에 연산자를 설치 → Calico 구성에 필요한 사용자 지정 리소스 다운로드(Calico 설치를 사용자 지정하려면 다운로드한 custom-resources.yaml 매니페스트를 로컬로 사용자 지정) → Calico를 설치하기 위해 매니페스트를 생성 → Calico 설치
```

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl get pod -n kube-system
```

---

## ansible

- 설치

```bash
sudo apt install ansible
```

- 설정

```bash
vi /etc/hosts
10.0.3.168  worker1
10.0.3.215	worker2    # 추가

ssh-keygen -q -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub
# 복사
# worker1,2 에서 vi ~/.ssh/authorized_keys 에 붙여넣기

ssh-keyscan worker1 >> ~/.ssh/known_hosts
ssh-keyscan worker2 >> ~/.ssh/known_hosts

mkdir /etc/ansible
vi /etc/ansible/hosts
worker1
worker2

vi ~/.ssh/config
Host worker1
        Hostname worker1
        IdentityFile ~/.ssh/id_rsa
        User root

Host worker2
        Hostname worker2
        IdentityFile ~/.ssh/id_rsa
        User root
```

- 확인

```bash
ansible all -m ping
```
