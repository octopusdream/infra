### 들어가기에 앞서

Prometheus 배포 도구: Helm (애플리케이션 배포 간편화 도구)
환경: Ubuntu 20.04(Master node1, Worker node2) 

### Goal
>
Helm 사용해 Bare Metal K8s Cluster 환경에 Prometheus를 배포한다.


## 프로메테우스 배포 전 요구사항

프로메테우스는 헬름으로 쉽게 설치 가능하다. 다만, NFS 디렉토리를 만들고, NFS 디렉토리를 쿠버네티스 환경에서 사용할 수 있도록 PV 와 PVC로 구성해야 한다. 또한, 온프레미스 환경이므로 MetalLB 를 구성해야 한다.
### Helm 설치
```
export DESIRED_VERSION=v3.2.1 # v3.2.1 으로 다운로드
wget https://raw.githubusercontent.com/sysnet4admin/_Book_k8sInfra/713e8464a0600d275d31897752641b79ea58a75b/ch5/5.2.3/helm-install.sh
```
### Helm 으로 MetalLB 구성하기

여기서는 컨테이너 인프라 환경 구축을 위한 쿠버네티스/도커 책을 따라 설치를 진행해본다.
![](https://velog.velcdn.com/images/hyunshoon/post/bde16e28-f308-4388-819c-9d6481f2778b/image.png)

```
helm repo add edu https://iac-source.github.io/helm-charts
helm repo list # 배포 되었는지 확인
helm repo update
helm install metallb edu/metallb --namespace=metallb-system --create-namespace --set controller.tag=v0.8.3 --set speaker.tag=v0.8.3 --set configmap.ipRange=192.168.8.111-192.168.8.130
```
IP range: 192.168.8.111-192.168.8.130 로 설정
![](https://velog.velcdn.com/images/hyunshoon/post/f8695e3c-6e55-4ed3-adc1-bc2f7d208ab4/image.png)
metalLB 가 제대로 배포되었는지 확인

간단하게 디플로이먼트 배포하여 IP 가 정상적으로 할당되었는지 확인.
```
 ⚡ root@master  ~/prometheus  k create deployment echo-ip --image=sysnet4admin/echo-ip
deployment.apps/echo-ip created
 ⚡ root@master  ~/prometheus  k expose deployment echo-ip --type=LoadBalancer --port=80
service/echo-ip exposed
 ⚡ root@master  ~/prometheus  k get svc echo-ip
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
echo-ip   LoadBalancer   10.111.110.176   192.168.8.111   80:31418/TCP   7s
```
![](https://velog.velcdn.com/images/hyunshoon/post/9f6a2de7-1682-40a8-8310-810d9df9f8c7/image.png)

### NFS server 배포

```
[Master]
apt-get -y install nfs-server
systemctl enable nfs-server
systemctl status nfs-server

[Worker]
apt-get -y install nfs-common
systemctl restart nfs-utils
systemctl enable nfs-utils

[Master]
./nfs-exporter.sh prometheus/server/
k apply -f prometheus-server-volume.yaml
chown 1000:1000 /nfs_shared/prometheus/server


 ✘ ⚡ root@master  ~/prometheus  k get pv prometheus-server
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS   REASON   AGE
prometheus-server   10Gi       RWX            Retain           Bound    default/prometheus-server                           34m
 ✘ ⚡ root@master  ~/prometheus  k get pvc prometheus-server
NAME                STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
prometheus-server   Bound    prometheus-server   10Gi       RWX                      
```

  
  
## 프로메테우스 배포

```
wget https://raw.githubusercontent.com/sysnet4admin/_Book_k8sInfra/main/ch6/6.2.1/prometheus-server-preconfig.sh
wget https://raw.githubusercontent.com/sysnet4admin/_Book_k8sInfra/main/ch6/6.2.1/prometheus-install.sh
wget https://raw.githubusercontent.com/sysnet4admin/_Book_k8sInfra/main/ch6/6.2.1/prometheus-server-volume.yaml
wget https://raw.githubusercontent.com/sysnet4admin/_Book_k8sInfra/main/ch6/6.2.1/nfs-exporter.sh
```

prometheus-server-preconfig.sh 경로 맞게 수정 후 실행
```
./prometheus-server-preconfig.sh
./prometheus-install.sh
```
![](https://velog.velcdn.com/images/hyunshoon/post/a8fecd2c-b010-453f-a960-32b246cc6cc7/image.png)

node-exporter 가 여러개인 이유는 각 노드마다 메트릭을 수집하기 위해 데몬셋으로 설치했기 때문이다.

### 🤦‍♂️Trouble!
![](https://velog.velcdn.com/images/hyunshoon/post/a8fecd2c-b010-453f-a960-32b246cc6cc7/image.png)
>
prometheus-server pod가 ContainerCreating 상태로 문제가 생겼다.
>
원인은 프로메테우스 설치 전 배포해줘야하는 nfs-server를 깜빡해서 mount에 실패했기 때문.
>
따라서 다음과 같은 작업이 필요하다.
>
1. 생성한 pv, pvc, prometheus-server pod 등을 지운다.
2. nfs-server 배포
3. prometheus-server-volume.yaml 재 배포


1. 생성한 pv, pvc 삭제


```
k delete -f prometheus-server-volume.yaml
⚡ root@master  ~/prometheus  k get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                       STORAGECLASS   REASON   AGE
prometheus-server   10Gi       RWX            Retain           Terminating   default/prometheus-server                           131m
```


delete 해도 STATUS == Terminating 상태에서 지워지지 않는다.
kubectl delete pv (pv name) --grace-period=0 --force 명령어로도 삭제가 불가능.

[쿠버네티스 공식 문서](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#finalizers) 에 따르면 삭제가 불가능 한 이유는 Finalizer 때문이다. [finalizer에 대해 짧게 정리 하였다.](https://velog.io/@hyunshoon/kubernetes-pv-pvc-%EC%82%AD%EC%A0%9C-%EC%95%88%EB%90%A0-%EB%95%8C-Finalizer) 해당 포스팅에서는 해결만 한다.
```
kubectl edit pv
kubectl edit pvc
```
![](https://velog.velcdn.com/images/hyunshoon/post/d5bef399-1ca2-4903-8f40-2d113f116ef7/image.png)
위 finalizer를 삭제해준다.

```

 ✘ ⚡ root@master  ~/prometheus  k get pv
No resources found
 ⚡ root@master  ~/prometheus  k get pvc
No resources found in default namespace.

```

삭제 완료

2. nfs-server 배포는 위 참고
3. prometheus-server-volume.yaml 재 배포

```
 ⚡ root@master  ~/prometheus  k apply -f prometheus-server-volume.yaml
persistentvolume/prometheus-server created
persistentvolumeclaim/prometheus-server created
```
### 배포 확인

![](https://velog.velcdn.com/images/hyunshoon/post/6786729e-a451-4d7d-86b4-d91277d9dbe1/image.png)

Pod가 정상적으로 배포 되었다!

```
 ⚡ root@master  ~  kubectl get svc prometheus-server
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
prometheus-server   LoadBalancer   10.104.227.46   192.168.8.111   80:31019/TCP   18h
```
EXTERNAL-IP 로 접속하여 웹 UI 사용
![](https://velog.velcdn.com/images/hyunshoon/post/627c9476-707a-47ac-97a2-9ef2ed7983ea/image.png)


Reference
- 조훈, 심근우, 문성주. 『컨테이너 인프라 환경 구축을 위한 쿠버네티스/도커』길벗, 2021
- https://github.com/sysnet4admin/_Book_k8sInfra/tree/main/ch6
- https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#finalizers
- https://kubernetes.io/ko/docs/concepts/overview/working-with-objects/finalizers/
- https://etloveguitar.tistory.com/141#:~:text=%EC%97%AC%EA%B8%B0%EC%84%9C%20%EB%A7%90%ED%95%98%EB%8A%94%20helm%20chart%20%EB%9E%80,%EB%A5%BC%20%EB%B0%B0%ED%8F%AC%ED%95%A0%20%EC%88%98%20%EC%9E%88%EB%8B%A4.

