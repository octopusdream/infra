### 참고

[https://teichae.tistory.com/entry/Argo-CD를-이용한-Canary-배포-4](https://teichae.tistory.com/entry/Argo-CD%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%9C-Canary-%EB%B0%B0%ED%8F%AC-4)

[https://www.infracloud.io/blogs/progressive-delivery-argo-rollouts-canary-deployment/](https://www.infracloud.io/blogs/progressive-delivery-argo-rollouts-canary-deployment/)

[https://github.com/argoproj/argo-rollouts/releases?page=2](https://github.com/argoproj/argo-rollouts/releases?page=2)

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
  replicas: 5
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

![image](https://user-images.githubusercontent.com/93571332/205253958-9a1fe791-526f-4d3b-b427-8bc5ae0e4799.png)
