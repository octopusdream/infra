## Why Canary?

참고 ) [https://github.com/octopusdream/infra/blob/zooneon/docs/deployment_strategies.md](https://github.com/octopusdream/infra/blob/zooneon/docs/deployment_strategies.md)

배포 전략으로 대표적으로 Blue-Green Deployment, Canary Deployment, Rolling Deployment 가 있다. **Blue-Green Deployment** 는 간단하고 빠르며 구현하기 쉽고 문제 발생 시 롤백을 쉽게 할 수 있다. 이미 실행중 이기에 이전 버전을 별도로 배포할 필요가 없으나 이로 인해 동시에 상당한 파드가 배포되므로 기존 배포보다 비용적으로 더 비싸다. **Canary Deployment**는 모든 배포 전략 중에 안전한 편에 속한다. 실제 실시간 트래픽으로 테스트가 진행되고 마찬가지로 문제 발생 시 롤백을 쉽게 할 수 있다. 짧은 downtime을 가지는 것이 특징이지만, 구현이 블루 그린보다 복잡한 편에 속한다. 또한 블루 그린보다 배포 속도가 느리다. **Rolling Deployment는**  Kubernetes 상에서의 기본 배포로 역시 문제 발생 시 롤백을 쉽게 할 수 있다. 정해놓은 단위로, 순차적으로 새로운 버전으로 교체해 나아간다. 짧은 downtime을 가지지만, 구현이 복잡하다. 이번 프로젝트 환경에서 애플리케이션 자체가 가볍기에 자원이 부족하여 자원을 제한해야 할 필요가 없었고 빠른 배포보다는 실제로 새로운 버전에 트래픽을 늘려가며 테스트를 해보는 것이 더 중요하다고 생각했기에 Canary 배포를 선택하였다.

## ****Argo**** Rollout ****컨트롤러 설치****

Argo Rollout 컨트롤러 설치를 위한 네임스페이스를 생성하고 아래 명령을 통해 Rollout 를 설치

```bash
# kubernetes version 이 1.21 이므로 argocd rollout v1.0.7을 설치
$ kubectl create namespace argo-rollouts
$ kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.0.7/install.yaml
```

Rollout 컨트롤러 및 리소스와 쉽게 상호 작용할 수 있도록 Argo Rollouts Kubectl 플러그인 을 설치

```bash
$ curl -LO https://github.com/argoproj/argo-rollouts/releases/download/v1.0.7/kubectl-argo-rollouts-linux-amd64
$ chmod +x ./kubectl-argo-rollouts-linux-amd64
$ sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
$ kubectl argo rollouts version
kubectl-argo-rollouts: v1.0.7+1d8052e
  BuildDate: 2021-09-23T23:17:03Z
  GitCommit: 1d8052ec0dc4358b8b29831aff2eb13f78f647c1
  GitTreeState: clean
  GoVersion: go1.16.3
  Compiler: gc
  Platform: linux/amd64
```

Argo Rollout에 대한 자체 GUI에 액세스

```bash
$ kubectl argo rollouts dashboard
INFO[0000] Argo Rollouts Dashboard is now available at localhost 3100
```

## ****Canary Deployment with Argo Rollouts****

Canary 배포 전략을 사용하여 배포한다.

우선 HPA 설정을 진행한다.

참고 ) [https://github.com/octopusdream/infra/blob/zooneon/docs/horizontal_pod_autoscaling.md](https://github.com/octopusdream/infra/blob/zooneon/docs/horizontal_pod_autoscaling.md)

최소 replicas 개수, 최대 replicas 개수를 설정하고, CPU 사용률이 60% 이상일 경우 생성되도록 매니패스트 파일을 구성한다.

```bash
---
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: flaskdemo-hpa
spec:
  maxReplicas: 36
  minReplicas: 6
  scaleTargetRef:
    apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    name: flaskdemo
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 60
```

setWeight는 보내야 하는 트래픽의 비율을 나타내며 pause구조는 Rollout을 일시 중지한다.

pause 내에 duration가 설정되어 있으면 duration내에 값을 기다릴 때까지 Rollout은 다음 단계로 진행하지 않는다. 

Pod 안에서 실행되는 컨테이너가 사용하는 리소스가 무분별하게 사용되지 않도록 requests와 limits를 설정하여 리소스를 제한한다.

트래픽의 20%를 카나리아로 전송한 다음 결과를 확인하고 수동 프로모션을 수행한 이후, 점진적으로 자동화된 트래픽을 증가시키는 canary 매니패스트 파일을 구성한다.

```bash
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  labels:
    app: flaskdemo
  name: flaskdemo
spec:
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 20}
      - setWeight: 60
      - pause: {duration: 20}
      - setWeight: 80
      - pause: {duration: 20}
  revisionHistoryLimit: 2 # deployment에서 유지해야 하는 이전 replicaset의 수를 명시
  selector:
    matchLabels:
      app: flaskdemo
  template:
    metadata:
      labels:
        app: flaskdemo
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - flaskdemo
                topologyKey: kubernets.io/zone
      containers:
      - image: jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:26
        name: flaskdemo
        resources:
          requests: 
            cpu: "500m"
            memory: "256Mi"
          limits: 
            cpu: "500m"
            memory: "256Mi"
status: {}
```

매니패스트 파일에 LoadBalancer를 사용하여 서비스를 외부에 노출시킨다.

```bash
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
  topologyKeys:
    - "kubernetes.io/hostname"
    - "topology.kubernetes.io/zone"
    - "*"
```

## **Updating a Rollout**

Git을 연결해 두었기에 commit 시  20% 정도 트래픽이 새로운 버전으로 이동하고 정지한다.

아래 명령어로 업데이트가 되는 상세 정보가 확인 가능하다.

```bash
$ kubectl argo rollouts get rollout flaskdemo --watch
```

## **Promoting a Rollout**

위에 20% 트래픽에서 새버전 파드가 성공을 할 시 아래와 같은 명령어를 실행하여 promotion 이후 다음 단계로 트래픽을 새 버전에 줄 수 있도록 한다.

```bash
$ kubectl argo rollouts promote flaskdemo
```

모든 단계가 한번에 성공하면 새로운 ReplicaSet "stable"로 확인된다.

## **Aborting a Rollout**

github에서 매니패스트 파일 변경을 통해 새로운 버전을 배포하여 새 버전에 트래픽 20%를 먼저 실행한다.

어떠한 오류나 특정 이유로 인해 배포를 멈추러면 아래와 같은 명령어를 사용한다.

`kubectl argo rollouts abort flaskdemo`

```bash
$ **kubectl argo rollouts abort flaskdemo**
rollout 'flaskdemo' aborted

$ kubectl argo rollouts get rollout flaskdemo --watch
Name:            flaskdemo
Namespace:       default
Status:          **✖ Degraded**
Message:         RolloutAborted: Rollout aborted update to revision 15
Strategy:        Canary
  Step:          0/8
  SetWeight:     0
  ActualWeight:  0
Images:          jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:**21** (**stable**)
Replicas:
  Desired:       6
  Current:       6
  Updated:       0
  Ready:         6
  Available:     6

NAME                                   KIND        STATUS        AGE    INFO
⟳ flaskdemo                            Rollout     ✖ Degraded    18h
├──# revision:15
│  └──⧉ **flaskdemo-6cc98bf786**           ReplicaSet  • ScaledDown  5m11s  **canary**
├──# revision:14
│  └──⧉ **flaskdemo-7dc589b87f**           ReplicaSet  ✔ Healthy     87m    **stable**
│     ├──□ flaskdemo-7dc589b87f-6gxrs  Pod         ✔ Running     74m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-vzhhv  Pod         ✔ Running     74m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-cskdn  Pod         ✔ Running     73m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-pnbzr  Pod         ✔ Running     72m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-ns82m  Pod         ✔ Running     72m    ready:1/1
│     └──□ flaskdemo-7dc589b87f-rksvd  Pod         ✔ Running     50s    ready:1/1
├──# revision:13
│  └──⧉ flaskdemo-7f87df45f6           ReplicaSet  • ScaledDown  9h
├──# revision:7
│  └──⧉ flaskdemo-6578c5bc48           ReplicaSet  • ScaledDown  17h
├──# revision:2
│  └──⧉ flaskdemo-75b55976dc           ReplicaSet  • ScaledDown  18h
└──# revision:1
   └──⧉ flaskdemo-786bd777dd           ReplicaSet  • ScaledDown  18h
```

다시 이전 버전 이미지를 설정하여 업데이트를 진행한다.

`kubectl argo rollouts set image flaskdemo flaskdemo=jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:21`

새로운 버전을 다시 실행하고 싶으면 promotion을 진행해 주면 된다.

`kubectl argo rollouts promote flaskdemo`

```bash
$ kubectl argo rollouts promote flaskdemo
Name:            flaskdemo
Namespace:       default
Status:          **✔ Healthy**
Strategy:        Canary
  Step:          8/8
  SetWeight:     100
  ActualWeight:  100
Images:          jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:**22** (**stable**)
Replicas:
  Desired:       6
  Current:       6
  Updated:       6
  Ready:         6
  Available:     6

NAME                                   KIND        STATUS        AGE    INFO
⟳ flaskdemo                            Rollout     ✔ Healthy     18h
├──# revision:17
│  └──⧉ flaskdemo-6cc98bf786           ReplicaSet  ✔ Healthy     24m    **stable**
│     ├──□ flaskdemo-6cc98bf786-j5bf9  Pod         ✔ Running     9m39s  ready:1/1
│     ├──□ flaskdemo-6cc98bf786-snsfn  Pod         ✔ Running     9m39s  ready:1/1
│     ├──□ flaskdemo-6cc98bf786-t2dgh  Pod         ✔ Running     106s   ready:1/1
│     ├──□ flaskdemo-6cc98bf786-b4qzv  Pod         ✔ Running     84s    ready:1/1
│     ├──□ flaskdemo-6cc98bf786-wmn62  Pod         ✔ Running     63s    ready:1/1
│     └──□ flaskdemo-6cc98bf786-99m75  Pod         ✔ Running     42s    ready:1/1
├──# revision:16
│  └──⧉ flaskdemo-7dc589b87f           ReplicaSet  • ScaledDown  106m
└──# revision:13
   └──⧉ flaskdemo-7f87df45f6           ReplicaSet  • ScaledDown  9h
```

### 참고

[https://github.com/argoproj/argo-rollouts/releases?page=2](https://github.com/argoproj/argo-rollouts/releases?page=2)

[https://www.infracloud.io/blogs/progressive-delivery-argo-rollouts-canary-deployment/](https://www.infracloud.io/blogs/progressive-delivery-argo-rollouts-canary-deployment/)

[Basic Usage - Argo Rollouts - Kubernetes Progressive Delivery Controller (argoproj.github.io)](https://argoproj.github.io/argo-rollouts/getting-started/)

[https://argoproj.github.io/argo-rollouts/features/specification/](https://argoproj.github.io/argo-rollouts/features/specification/)

[https://codefresh.io/blog/argo-rollouts-1-0-milestone/](https://codefresh.io/blog/argo-rollouts-1-0-milestone/)
