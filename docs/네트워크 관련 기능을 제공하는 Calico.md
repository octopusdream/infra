우리는 쿠버네티스를 설치하는 첫 단계인 kops, kubeadm, kubespray, GKE, EKS 중 kubeadm을 선택하였고, Calico, Cilium, Flannel 등의 클러스터 네트워킹을 제대로 동작시키기 위한 다양한 네트워크 플러그인 중 Calico를 선택하였다. 

그러므로 3rd-party CNI 플러그인 중 하나인 Calico에 대해 알아보기 위해 아래와 같은 순서로 정리해보려한다.

```
1. CNI(Container Network Interface)가 무엇인지 확인해본다.

2. Calico가 무엇이며 어떤 역할을 하고 어떻게 동작하는지 확인해본다.

3. Calico CNI가 파드to파드 통신, 외부 통신, 다른 노드 간 파드to파드 통신에서 어떻게 동작하는지 확인해본다.

4. Calico의 네트워크 모드로는 IPIP 모드, Direct 모드, BGP 모드, VXLAN 모드가 있는데 각각 어떻게 설정이 되어 있으며 어떻게 통신 되는지 확인해본다.

5. Pod 간 통신할 떄 Pod 패킷을 암호화할 수 있는 방법을 확인해본다. (네트워크 레벨)

6. Calico의 네트워크 접근 통제하는 방법을 확인해본다. (Network Policy)
```

---
# 1. CNI가 무엇인가?

CNCF(Cloud Native Computing Foundation)의 프로젝트 중 하나인 CNI는 컨테이너 간의 네트워킹을 제어할 수 있는 플러그인을 만들기 위한 표준이다.

CNI는 컨테이너의 netns(network namespace)를 세팅하고, 호스트의 bridge와 컨테이너 사이에 veth를 연결하여 각 네트워크 인터페이스마다 대역에 맞는 IP를 할당하는 작업을 수행한다.

CNI는 반드시 K8S가 아닌 다른 런타임에서도 동일하게 동작할 수 있다.

### Kubernetes에서의 CNI와 CNI 플러그인
쿠버네티스에서 pod 간의 통신을 위해 CNI를 사용한다.

쿠버네티스는 기본적으로 'kubenet' 이라는 자체적인 기본 CNI 플러그인을 제공하지만 네트워크 기능이 매우 제한적인 단점이 있다. ('kubenet'은 컨테이너간의 노드간 교차 네트워킹도 지원되지 않는다.)

그 단점을 보완하기 위하여, 3rd-party CNI 플러그인을 사용하는데 종류로는 Flannel, Calico, Weavenet, NSX 등 다양한 종류의 3rd-party CNI 플러그인들이 존재하며, 이들 간의 특징들도 각각 다르다.

---
# 2. Calico는 무엇인가
Calico는 Container, VM 환경에서 L3기반 Virtual Network를 구축하게 도와주는 Tool이다.

Calico는 CNI (Container Network Inteface)를 지원하기 때문에 Kubernetes나 Meos에서 Network Plugin으로 동작 할 수 있다.

### Calico의 구성요소
![image](https://user-images.githubusercontent.com/88362207/202438038-dba7b385-6149-4b5e-8e59-02188347c87b.png)

Calico는 크게 etcd, felix, bird, confd 4가지의 구성요소로 이루어져 있다.
- etcd는 Kubernetes Cluster에서 동작한다.
- felix, confd, bird는 모든 Kubernetes Host(master, worker) 위에서 데몬셋으로 calico-node Pod가 배치되어 안에서 동작한다. calico controller파드는 deployment로 배치된다.
- calico-node Pod은 Host(Node)의 Network Namespace를 이용하기 때문에 calico-node Pod안에서 동작하는 App은 Host의 Network 설정을 조회하거나 제어 할 수 있다.

#### bird(BGP)
bird는 각 노드마다 존재하는 BGP 데몬이다. BGP 데몬은 다른 노드에 있는 BGP 데몬들에 라우팅 정보를 공유하는 역할을 담당한다.
대표적인 네트워크 구성(topology)으로는 노드별 full mesh(그물형)가 있다. 이 구성은 각 노드끼리 모두 BGP peer를 가지며, 가장 기본적인 설정이다. 또한 이것은 작은 규모의 클러스터에 적합하다.
![image](https://user-images.githubusercontent.com/88362207/202439091-4690ca4d-8e17-4b4e-bcec-3b6038a16b1a.png) 
더 큰 규모의 클러스터에서는 BGP full mesh peering 방법은 한계가 있어 사용하지 않는다. 이 경우에는 Route Reflector 방법을 사용하여 일부 노드에서만 라우팅 정보를 전파는 방법을 사용할 수 있다. 모든 노드끼리 peer를 구성하는게 아니라 특정 노드만 Route Reflector(RR)로 구성하여 RR로 설정된 노드와만 통신하여 라우팅 정보를 주고 받는 것이다. 라우팅 정보를 전파해야 하는 경우 RR로만 전달하면 RR이 자신과 peer를 맺고 있는 BGP로 전파를 한다.
![image](https://user-images.githubusercontent.com/88362207/202602064-7199e259-58b2-452b-b97b-b827710d9a1c.png)
Route Reflector 방법은 한개 이상의 Route Reflector를 두어 가용성을 높힐 수 있다. bird 데몬 대신에 외부 물리 장비(BGP 프로토콜을 수행하는 일반적인 라우터 장비(이것을 소프트웨어로 구현한 것이 bird이다.))를 이용하는 방법도 있다.
#### felix
Felix 데몬도 calico-node 컨테이너 안에서 동작하며 다음과 같은 동작을 수행한다.
```
쿠버네티스 etcd로부터 정보를 읽습니다.
라우팅 테이블을 만듭니다.
iptable을 조작합니다.(kube-proxy가 iptables 모드인 경우)
ipvs을 조작합니다.(kube-proxy가 ipvs 모드인 경우)
```
각 노드에 할당된 pod의 IP 대역이 BGP로 전파되면 그 대역과 정상적으로 통신이 이루어질 수 있도록 iptables와 라우팅테이블 등을 조정한다.

호스트의 라우팅 테이블을 조작하는 역할을 담당합니다.

#### confd
경량의 configuration management 를 위한 오픈소스로 툴로, datastore를 모니터링 하고 있다가 BGP 설정이나 IPAM 정보 등이 변경되면 변경된 값이 반영될 수 있도록 트리거하는 역할을 한다.
#### etcd


이렇게 전달받은 정보를 리눅스 라우팅 테이블에 추가하는 것은 Felix가 수행하고, 상대방 노드의 pod 대역을 BGP프로토콜로 bird를 통해 전달받아서 라우팅 테이블과 iptable 룰을 조정한다.
configd는 datastore로 지정된 저장소를 모니터링하고 있다가 값의 변경이 발생하면 트리거 발생시켜서 적용될 수 있도록 한다.
이러한 과정을 거쳐 각 노드에는 pod의 ip 대역으로 사용할 대역이 IPAM에 의해 정해진다.

---
# 라우팅 모드
