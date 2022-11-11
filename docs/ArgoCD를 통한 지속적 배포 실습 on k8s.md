## 사전 준비 사항

Ubuntu 버전 : 20.04.5

kubernetes Clinet 버전 : 1.21.1

kunernetes Server 버전 : 1.21.14

helm 버전 : 3.2.1

## Argocd Helm으로 설치

### 서버에 Argocd 설치 및 네임스페이스 생성

```bash
root@master:~# curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/2.1.1/argocd-linux-amd64
root@master:~# chmod +x /usr/local/bin/argocd
root@master:~# kubectl create ns argo
```

### Argocd helm repo에 등록

```bash
root@master:~# helm repo add argo https://argoproj.github.io/argo-helm
```

### helm 으로 argocd 설치

```bash
# 설치 관련 파일 clone
root@master:~# git clone https://github.com/argoproj/argo-helm.git
# 사전에 metallb 설정해둠
root@master:~# vi argo-helm/charts/argo-cd/values.yaml
...
## Server service configuration
  service:
    # -- Server service annotations
    annotations: {}
    # -- Server service labels
    labels: {}
    # -- Server service type
    type: **loadBalancer**  # 수정!
    # -- Server service http port for NodePort service type (only if `server.service.type` is set to "NodePort")
...
root@master:~# helm install argo -n argo argo/argo-cd -f argo-helm/charts/argo-cd/values.yaml
```

### 버전 에러 발생

```bash
Error: chart requires kubeVersion: >=1.22.0-0 which is incompatible with Kubernetes v1.21.14
```

### 결론

쿠버네티스 버전을 올리면 해결할 수 있는 오류이지만, 초반에 설계한 k8s 버전을 변경하는 것은 상당히 고려해야 할 부분이었고 버전을 올릴 시 다른 곳에서 오류가 뜨는 것이 우려가 되었다.

최종적으로 내린 결론은 argocd는 helm을 사용하지 않고  다른 방식으로 설치를 한다는 것이다.

## Argocd Helm 일반 설치

### Argocd 네임스페이스 생성

```bash
root@master:~# kubectl create namespace argocd
```

### Argocd CLI 설치

```bash
root@master:~# curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
root@master:~# chmod +x /usr/local/bin/argocd
```

### 쿠버네티스 클러스터 상에 배포 및 외부 접근 설정

```bash
root@master:~# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
root@master:~# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### 정상 배포되었는지 확인

```bash
root@master:~# kubectl get all -n argocd
```

### ArgoCD 계정 비밀번호 확인

```bash
root@master:~# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
# 웹 상에서 로그인하고 비밀번호 변경
```

### 참고

[https://argo-cd.readthedocs.io/en/stable/getting_started/](https://argo-cd.readthedocs.io/en/stable/getting_started/)
