## Why Canary?

참고 ) 

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

Argo Rollout에 대한 자체 **GUI에** 액세스

```bash
$ kubectl argo rollouts dashboard
INFO[0000] Argo Rollouts Dashboard is now available at localhost 3100
```

## ****Canary Deployment with Argo Rollouts****

Canary 배포 전략을 사용하여 배포한다.

setWeight는 보내야 하는 트래픽의 비율을 나타내며 pause구조는 Rollout을 일시 중지한다.

pause 내에 duration가 설정되어 있으면 duration내에 값을 기다릴 때까지 Rollout은 다음 단계로 진행하지 않는다. 

```bash
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  labels:
    app: flaskdemo
  name: flaskdemo
spec:
  replicas: 6
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: flaskdemo
  template:
    metadata:
      labels:
        app: flaskdemo
    spec:
      containers:
      - image: jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:15
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

 같이 Argo Rollouts 콘솔에 배포된 flask 앱을 확인

![image](https://user-images.githubusercontent.com/93571332/205426872-07e67c5e-19ba-4be4-ad5e-29666242faf9.png)

## **Updating a Rollout**

Git을 연결해 두었기에 commit 시  20% 정도 트래픽이 새로운 버전으로 이동하고 정지한다.

아래 명령어로 업데이트가 되는 상세 정보가 확인 가능

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

첫번째로, 새로운 버전을 배포를 한다.

```bash
$ kubectl argo rollouts get rollout flaskdemo --watch
Name:            flaskdemo
Namespace:       default
Status:          ॥ Paused
Message:         CanaryPauseStep
Strategy:        Canary
  Step:          1/8
  SetWeight:     20
  ActualWeight:  28
Images:          jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:21 (**stable**)
                 jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:22 (**canary**)
Replicas:
  Desired:       6
  Current:       7
  Updated:       2
  Ready:         7
  Available:     7

NAME                                   KIND        STATUS        AGE    INFO
⟳ flaskdemo                            Rollout     ॥ Paused      18h
├──# revision:15
│  └──⧉ **flaskdemo-6cc98bf786**           ReplicaSet  ✔ Healthy     2m14s  **canary**
│     ├──□ flaskdemo-6cc98bf786-6g7hb  Pod         ✔ Running     2m14s  ready:1/1
│     └──□ flaskdemo-6cc98bf786-b2mtq  Pod         ✔ Running     2m14s  ready:1/1
├──# revision:14
│  └──⧉ **flaskdemo-7dc589b87f**           ReplicaSet  ✔ Healthy     84m    **stable**
│     ├──□ flaskdemo-7dc589b87f-6gxrs  Pod         ✔ Running     71m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-vzhhv  Pod         ✔ Running     71m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-cskdn  Pod         ✔ Running     70m    ready:1/1
│     ├──□ flaskdemo-7dc589b87f-pnbzr  Pod         ✔ Running     69m    ready:1/1
│     └──□ flaskdemo-7dc589b87f-ns82m  Pod         ✔ Running     69m    ready:1/1
├──# revision:13
│  └──⧉ flaskdemo-7f87df45f6           ReplicaSet  • ScaledDown  9h
├──# revision:7
│  └──⧉ flaskdemo-6578c5bc48           ReplicaSet  • ScaledDown  17h
├──# revision:2
│  └──⧉ flaskdemo-75b55976dc           ReplicaSet  • ScaledDown  18h
└──# revision:1
   └──⧉ flaskdemo-786bd777dd           ReplicaSet  • ScaledDown  18h
```

새로운 버전을 할 시, 어떠한 오류나 특정 이유로 인해 배포를 멈추러면 아래와 같은 명령어를 사용한다.

```bash
$ kubectl argo rollouts abort flaskdemo
rollout 'flaskdemo' aborted

$ kubectl argo rollouts get rollout flaskdemo --watch
Name:            flaskdemo
Namespace:       default
Status:          ✖ Degraded
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

```bash
$ kubectl argo rollouts set image flaskdemo flaskdemo=jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:21
Name:            flaskdemo
Namespace:       default
Status:          ॥ Paused
Message:         CanaryPauseStep
Strategy:        Canary
  Step:          1/8
  SetWeight:     20
  ActualWeight:  28
Images:          jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:21 (**stable**)
                 jenkins-1d89f623e089d4f6.elb.ap-northeast-3.amazonaws.com:5001/flask_test:22 (**canary**)
Replicas:
  Desired:       6
  Current:       7
  Updated:       2
  Ready:         7
  Available:     7

NAME                                   KIND        STATUS        AGE    INFO
⟳ flaskdemo                            Rollout     ॥ Paused      18h
├──# revision:17
│  └──⧉ **flaskdemo-6cc98bf786**           ReplicaSet  ✔ Healthy     15m    **canary**
│     ├──□ flaskdemo-6cc98bf786-j5bf9  Pod         ✔ Running     65s    ready:1/1
│     └──□ flaskdemo-6cc98bf786-snsfn  Pod         ✔ Running     65s    ready:1/1
├──# revision:16
│  └──⧉ **flaskdemo-7dc589b87f**           ReplicaSet  ✔ Healthy     97m    **stable**
│     ├──□ flaskdemo-7dc589b87f-5rwm6  Pod         ✔ Running     5m51s  ready:1/1
│     ├──□ flaskdemo-7dc589b87f-5nxhf  Pod         ✔ Running     5m50s  ready:1/1
│     ├──□ flaskdemo-7dc589b87f-kqrwv  Pod         ✔ Running     5m48s  ready:1/1
│     ├──□ flaskdemo-7dc589b87f-c5ff2  Pod         ✔ Running     5m46s  ready:1/1
│     └──□ flaskdemo-7dc589b87f-kjn75  Pod         ✔ Running     5m44s  ready:1/1
├──# revision:13
│  └──⧉ flaskdemo-7f87df45f6           ReplicaSet  • ScaledDown  9h
├──# revision:7
│  └──⧉ flaskdemo-6578c5bc48           ReplicaSet  • ScaledDown  18h
└──# revision:2
   └──⧉ flaskdemo-75b55976dc           ReplicaSet  • ScaledDown  18h
```

```bash
$ kubectl argo rollouts promote flaskdemo
Name:            flaskdemo
Namespace:       default
Status:          ✔ Healthy
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
