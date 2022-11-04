## 우리는 왜 여러 개의 Availability Zone에 클러스터를 구축해야 할까?

하나의 Availability Zone에 쿠버네티스 클러스터를 구축하는 것은 node failure가 발생해도 안정적으로 서비스를 운영할 수 있지만 zone failure에 대한 가용성은 보장하지 않는다. 

따라서 zone failure가 발생해도 안정적으로 서비스를 운영하기 위해서는 다중 Availability Zone을 이용해야 한다.

## 우리는 왜 3개의 Availability Zone을 이용할까?

우선 쿠버네티스 [공식문서](https://kubernetes.io/docs/setup/best-practices/multiple-zones/)에 따르면 쿠버네티스를 multiple zone에서 운영할 경우 control plane은 각기 다른 zone에 있어야 하고, 가용성이 우선이라면 적어도 3개의 zone을 선택할 것을 권장하고 있다.

또한 AWS의 EKS도 [고가용성 아키텍처](https://aws.amazon.com/ko/quickstart/architecture/amazon-eks/)를 위해 3개의 Availability Zone을 이용하고 있다.

마지막으로 etcd의 Raft 알고리즘을 고려해야 한다.

쿠버네티스는 backing storage로 etcd를 이용한다.

HA를 위해서 etcd를 컴포넌트로 갖고 있는 control plane 또한 클러스터링 해줘야 하는데 2대의 control plane을 클러스터링 하는 것은 HA에 도움이 되지 않는다.

이는 위에서 언급한 Raft 알고리즘과 관련이 있는데, 2대의 etcd에서 leader election을 수행하기 위해서는 etcd quorum이 2`(2/2+1)`를 만족해야 한다.

만약 여기서 1대의 etcd 서버가 죽게 되면 quorum을 만족할 수 없으므로 leader election에 실패하게 되고 결국 클러스터 전체에 장애가 발생하게 된다.

따라서 적어도 3대의 etcd 서버를 클러스터링 해야 하고, 하나의 Availability Zone이 outage되어도 가용성을 유지하기 위해선 3개의 zone을 이용해야 한다.

(하나의 zone에 2대, 나머지 zone에 1대를 둘 경우 2대를 보유하고 있는 zone이 outage될 경우 마찬가지로 quorum을 만족하지 못하므로 장애가 발생한다.)

물론 더 많은 Availability Zone을 이용하면 더 높은 가용성을 보장 받을 수 있지만 그만큼의 비용이 증가하게 된다.

(참고로 etcd [공식문서](https://etcd.io/docs/v3.5/faq/#what-is-maximum-cluster-size)에서는 최대 클러스터 사이즈로 5를 권장하고 있다.)

## 다중 AZ에서 노드들을 클러스터링 하는 방법

### Availability Zone bounded Auto Scaling groups

![asg1](https://user-images.githubusercontent.com/59433441/199960625-4facf6c6-032f-4237-9ffc-6baad4e5f92a.png)

각 AZ에 하나의 ASG를 생성하는 방법이다.

스토리지로 EBS를 사용하는 경우에 사용한다.

EBS의 경우 [EC2와 같은 zone에 있어야 하므로](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html) Auto Scaling Group을 각 AZ마다 생성할 수 있다.

(물론 여러 AZ에 하나의 ASG를 생성할 수 있지만 이에 따른 문제는 아래에 작성하였다.) 

worker 노드 그룹(하나의 ASG)에서 레이블을 사용하여 해당 가용 영역의 노드에 pod를 예약할 수 있다.

레이블(`topology.kubernetes.io/zone=ap-northeast-2b`)은 kubernetes cloud provider를 통해 노드에 자동으로 추가되고 AWS EBS CSI 드라이버를 통해 PersistentVolume에 자동으로 추가된다.

EBS 볼륨을 사용하는 pod가 reschedule되거나 인스턴스가 종료되는 경우 pod에 topology 레이블과 일치하는 nodeSelector가 있는지 확인해야 하며 각 AZ에 대해 별도의 배포를 실행해야 할 수 있다.

(해당 AZ의 볼륨을 사용하는 pod의 경우 nodeSelector를 통해 AZ를 명시해야 하며 이를 위해 AZ에 대해 별도의 배포가 실행될 수 있다.)

AZ당 ASG가 필요한 이유는 특정 AZ에 충분한 컴퓨팅 용량이 없고 pod를 scheduling 해야 하는 경우(ap-northeast-2b가 최대 용량이고 pod가 해당 AZ의 EBS 볼륨에 대한 액세스 권한으로 실행되어야 하는 경우) cluster autoscaler가 해당 AZ에 리소스를 추가할 수 있어야 하기 때문이다.

여러 AZ에 걸쳐 있는 하나의 ASG를 실행하는 경우 cluster autoscaler는 특정 AZ 에 인스턴스를 생성하도록 제어할 수 없다.

따라서 cluster autoscaler는 ASG에 리소스를 추가할 수 있지만 리소스가 필요한 특정 AZ를 구분할 수 없으므로 올바른 AZ에 인스턴스가 생성되기 위해 여러 번 시도될 수 있다.

AZ가 다운되는 경우 해당 AZ의 EBS 볼륨을 사용할 수 없으며 해당 볼륨을 요청하는 pod는 schedule되지 않는다.

AZ당 ASG를 사용하는 경우 각 ASG를 확장하도록 AZ마다 cluster autoscaler를 구성해야 한다.

이와 같이 AZ당 ASG를 실행하면 더 많은 ASG와 더 많은 배포(AZ당 하나)를 관리해야 하는 추가 오버헤드가 발생한다.

### Region bounded Auto Scaling groups

![asg2](https://user-images.githubusercontent.com/59433441/199960646-66b576e6-a645-4af0-9f31-bac4c5e7224a.png)

하나의 리전에 하나의 ASG를 생성하는 방법이다.

쿠버네티스에서 ASG를 사용하는 주요 이유는 클러스터에 컴퓨팅 리소스를 추가할 수 있기 때문이다.

리전별 ASG를 사용하면 여러 AZ에 컴퓨팅 리소스를 분산할 수 있으므로 애플리케이션이 AZ별 유지 관리에 탄력적으로 대처할 수 있다.

여러 AZ에 걸쳐 있는 ASG는 AZ별로 확장할 수 없지만 리소스가 AZ에 binding된 서비스(EBS 볼륨)을 사용하지 않는 경우 문제가 되지 않을 수 있다.

따라서 EBS 볼륨 대신 EFS 또는 RDS에 컨테이너 상태를 저장할 수 있는 경우 AZ에 걸쳐 있는 ASG를 사용해야 한다.

단일 ASG를 사용하면 아키텍처, 구성 및 구성 요소 간의 상호 작용이 단순화되어 시스템을 더 쉽게 이해하고 디버깅 하기 쉬워진다.

이를 통해 쿠버네티스에서의 배포(리전당 하나)를 단순화하고 고려해야 할 부분이 적기 때문에 관리 및 문제 해결에 용이하다.

여러 AZ에 걸쳐 있는 단일 ASG를 사용하면서 EBS 볼륨을 사용해야 하는 경우 VolumeBindingMode를 WaitForFirstConsumer로 변경할 수 있다.

WaitForFirstConsumer로 변경하면 PersistentVolumeClaim을 사용하는 pod가 생성될 때까지 PersistentVolume의 바인딩 및 프로비저닝이 지연된다.

pod가 기존 EBS 볼륨을 재사용할 때 EBS 볼륨이 존재하지 않는 AZ에서 pod가 schedule 될 수 있다.

### Individual instances without Auto Scaling groups

![asg3](https://user-images.githubusercontent.com/59433441/199960662-bc2f4041-1dfa-4600-8a5f-524f02994fed.png)

Auto Scaling group 없이 인스턴스들을 관리하는 방법이다.

ASG를 사용하지 않으면 AWS가 제공하는 cluster autoscaler를 사용할 수 없다.

ASG 대신 cluster-api와 같이 다른 provider의 서비스를 이용할 수 있지만, 이 경우 `CloudWatch scaling`과 같은 AWS의 일부 기능을 이용할 수 없다.

인스턴스를 확장하고 추적하는 프로비저닝 서비스가 없으면 ASG 외부에서(ASG 없이) 클러스터를 실행하는 것은 권장되지 않는다.

## Load Balancer Endpoints

다중 AZ에서 서비스를 제공할 때 AZ간 교차 트래픽을 줄이기 위해 externalTrafficPolicy 설정을 고려해야 한다.

externalTrafficPolicy의 기본값은 `Cluster`로, pod가 실행되는 worker 노드와 상관없이 모든 worker 노드가 모든 서비스에 대한 트래픽을 받는다.

worker 노드가 트래픽을 받으면 kube-proxy를 통해 서비스를 실행하는 노드로 전달된다.

단일 AZ 내에서는 문제가 되지 않지만 다중 AZ에서는 이 작업에서 추가적인 라우팅이 필요하다.

externalPolicy를 `Local`로 설정하면 서비스 컨테이너를 실행하는 인스턴스가 로드 밸런서 백엔드가 되어 로드 밸런서의 엔드포인트 수와 트래픽에 필요한 홉 수가 줄어든다.

Local policy를 사용하는 것의 장점은 source IP를 보존할 수 있다는 것이다.

패킷이 로드 밸런서를 통해 인스턴스와 서비스로 라우팅될 때 추가 kube-proxy 홉 없이 원래 요청의 IP를 보존할 수 있다.

externalTrafficPolicy를 설정하는 pod의 anti-affinity에 대한 고려도 필요하다.

anti-affinity가 없으면 모든 pod가 동일한 노드에 있게 되어 노드가 사라지면 문제가 발생할 수 있다.

인스턴스에 pod가 불균형하게 분산되는 경우에도 문제가 될 수 있다.

로드 밸런서는 각 인스턴스에서 실행되고 있는 pod의 개수는 모르고 인스턴스가 특정 포트에서 트래픽을 수신하고 있다는 것만 안다.

![lb1](https://user-images.githubusercontent.com/59433441/199961027-92babafd-355c-414e-a4d5-801d7ecd46ec.png)

2개의 인스턴스와 3개의 pod가 있는 경우 두 인스턴스는 트래픽의 50%를 수신하지만 로컬 kube-proxy가 트래픽을 균등하게 조정하기 때문에 2개의 컨테이너는 트래픽의 25%만 받게 된다.

![lb2](https://user-images.githubusercontent.com/59433441/199961018-e56c25bf-b8e8-4ca0-a41d-6082c5065817.png)

이런 불균형은 더 많은 인스턴스와 컨테이너가 있는 경우 더 급격하게 발생할 수 있다.

일정 간격 동안 deschedule 하지 않는 이상 쿠버네티스는 새 인스턴스가 추가될 때 reschedule 하지 않는다.

![lb3](https://user-images.githubusercontent.com/59433441/199961030-69c7719d-20f3-4237-932b-a4d295c3510d.png)

pod anti-affinity를 사용하면 트래픽이 고르게 분할되지 않을 수 있지만 배치 결정 중에 scheduler는 인스턴스에 컨테이너를 고르게 배포하려고 시도한다.

클러스터 크기가 변동하지만 pod가 자주 확장되지 않는 경우 descheduler를 실행하는 것이 좋은 아이디어일 수 있다.

## Service Topology

기본적으로 pod는 DNS 라운드 로빈을 통해 서비스 엔드포인트를 검색하고, failure domain, latency, cost를 고려하지 않고 트래픽을 라우팅한다.

다중 AZ 라우팅은 많은 데이터를 전송하는 경우 데이터 전송 비용을 고려해야 한다.

서비스 토폴로지는 서비스의 엔드포인트를 검색할 때 고려할 topologyKeys를 지정할 수 있도록 하여 stateful, stateless 컨테이너 모두에 유용하다.

이는 Istio의 로컬 로드 밸런싱과 유사하게 작동하며 오류를 줄이고 성능을 개선하며 불필요한 비용을 방지하는 데 도움이 된다.

동일한 호스트에서 실행되는 엔드포인트로 트래픽을 라우팅한 다음 동일한 AZ의 엔드포인트로 트래픽을 라우팅하는 예시는 다음과 같다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
  topologyKeys:
    - "kubernetes.io/hostname"
    - "topology.kubernetes.io/zone"
```

토폴로지 키와 동일한 호스트 이름 또는 동일한 영역을 가진 노드에서 실행 중인 서비스 엔드포인트가 없으면 서비스는 CoreDNS에서 서비스 엔드포인트로 반환되지 않으며 서비스 디스커버리는 실패하게 된다.

서비스 토폴로지 키에는 서비스에서 사용하려는 모든 엔드포인트 레이블이 포함되어야 한다.

매니페스트 파일에서 topologyKey 순서를 지정하여 서비스 엔드포인트가 검색되는 순서를 제어할 수 있다.

동일한 AZ 및 동일한 리전의 엔드포인트를 다른 엔드포인트보다 먼저 검색되게 하려면 다음과 같이 topologyKeys를 적용하면 된다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
  topologyKeys:
    - "topology.kubernetes.io/zone"
    - "topology.kubernetes.io/region"
    - "*"
```
