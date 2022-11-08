## master, worker1~3 사이 클러스터 구성을 완료

```bash
root@master:~$ kubectl get node
NAME      STATUS   ROLES                  AGE     VERSION
master    Ready    control-plane,master   5d20h   v1.21.1
worker1   Ready    <none>                 5d20h   v1.21.1
worker2   Ready    <none>                 5d20h   v1.21.1
```

## 헬름을 활용한 metallb 구축

### 헬름 설치

```bash
root@master:~/cicd$ curl -fsSL -o get_helm.sh \
https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
root@master:~/cicd$ chmod 700 get_helm.sh
root@master:~/cicd$ export DESIRED_VERSION=v3.2.1
root@master:~/cicd$ ./get_helm.sh
```

### 저장소 등록

```bash
root@master:~/cicd$ helm repo add edu https://iac-source.github.io/helm-charts
root@master:~/cicd$ helm repo list
NAME    URL
edu     https://iac-source.github.io/helm-charts
root@master:~/cicd$ helm repo update
```

### 차트를 설치

```bash
root@master:~/cicd$ helm install metallb edu/metallb \
--namespace=metallb-system \
--create-namespace \
--set controller.tag=v0.8.2 \
--set speaker.tag=v0.8.2 \
--set configmap.ipRange=192.168.8.201-192.168.8.239
NAME: metallb
LAST DEPLOYED: Thu Oct 27 15:53:47 2022
NAMESPACE: metallb-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
MetalLB load-balancer is successfully installed.
1. IP Address range 192.168.8.201-192.168.8.239 is available.
2. You can create a LoadBalancer service with following command below.
kubectl expose deployment [deployment-name] --type=LoadBalancer --name=[LoadBalancer-name] --port=[external port]
```

## 쿠버네티스 환경에서 젠킨스 설치

### nfs 서버 설치

```bash
# 워커 노드에서 실행
root@worker1:~$ apt install -y nfs-common

# 마스터 노드에서 실행
root@master:~$ apt install -y nfs-server
root@master:~$ systemctl enable nfs-server --now

root@master:~/cicd$ cat ./nfs-exporter.sh
#!/usr/bin/env bash
nfsdir=/nfs_shared/$1
if [ $# -eq 0 ]; then
  echo "usage: nfs-exporter.sh <name>"; exit 0
fi

if [[ ! -d $nfsdir ]]; then
  mkdir -p $nfsdir
  echo "$nfsdir 192.168.8.0/24(rw,sync,no_root_squash)" >> /etc/exports
  if [[ $(systemctl is-enabled nfs) -eq "disabled" ]]; then
    systemctl enable nfs-server
  fi
    systemctl restart nfs-server
fi
root@master:~/cicd$ chmod +x ./nfs-exporter.sh
root@master:~/cicd$ ./nfs-exporter.sh jenkins
root@master:~/cicd$ ls -n /nfs_shared
total 8
drwxr-xr-x 2 0 0 4096 11월  8 16:12 jenkins
...
root@master:~/cicd$ chown 1000:1000 /nfs_shared/jenkins/
root@master:~/cicd$ ls -n /nfs_shared
total 8
drwxr-xr-x 2 1000 1000 4096 11월  8 16:12 jenkins
...
```

### PV/PVC 구성과 Bound

```bash
root@master:~/cicd$ docker pull jenkins/inbound-agent:4.3-4
root@master:~/cicd$ docker pull jenkins/jenkins:2.249.3-lts-centos7
root@master:~/cicd$ docker pull kiwigrid/k8s-sidecar:0.1.193

root@master:~/cicd$ kubectl apply -f jenkins-volume.yaml
root@master:~/cicd$ kubectl get pv,pvc
NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                        STORAGECLASS   REASON   AGE
persistentvolume/jenkins             5Gi        RWX            Retain           Bound    defaul                                 t/jenkins                                     8s
persistentvolume/prometheus-server   10Gi       RWX            Retain           Bound    defaul                                 t/prometheus-server                           21h

NAME                                      STATUS   VOLUME              CAPACITY   ACCESS MODES                                    STORAGECLASS   AGE
persistentvolumeclaim/jenkins             Bound    jenkins             5Gi        RWX                                                            8s
persistentvolumeclaim/prometheus-server   Bound    prometheus-server   10Gi       RWX                                                            21h
```

### 젠킨스 설치

```bash
root@master:~/cicd$ cat jenkins-install.sh
#!/usr/bin/env bash
jkopt1="--sessionTimeout=1440"
jkopt2="--sessionEviction=86400"
jvopt1="-Duser.timezone=Asia/Seoul"
jvopt2="-Dcasc.jenkins.config=https://raw.githubusercontent.com/beomtaek/cicd_samplecode/4b32b6f7a3ab3cb11fa02847fa0aca6b7f2309fc/jenkins-config.yaml"
jvopt3="-Dhudson.model.DownloadService.noSignatureCheck=true"

helm install jenkins edu/jenkins \
--set persistence.existingClaim=jenkins \
--set master.adminPassword=admin \
--set master.nodeSelector."kubernetes\.io/hostname"=**master** \
--set master.tolerations[0].key=node-role.kubernetes.io/master \
--set master.tolerations[0].effect=NoSchedule \
--set master.tolerations[0].operator=Exists \
--set master.runAsUser=1000 \
--set master.runAsGroup=1000 \
--set master.tag=2.249.3-lts-centos7 \
--set master.serviceType=LoadBalancer \
--set master.servicePort=80 \
--set master.jenkinsOpts="$jkopt1 $jkopt2" \
--set master.javaOpts="$jvopt1 $jvopt2 $jvopt3"
root@master:~/cicd$ sh jenkins-install.sh
root@master:~/lab2/cicd_samplecode# kubectl get svc
NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
jenkins                         LoadBalancer   10.108.95.230   192.168.8.112   80:31233/TCP   35m
jenkins-agent                   ClusterIP      10.106.97.196   <none>          50000/TCP      35m
kubernetes                      ClusterIP      10.96.0.1       <none>          443/TCP        6d1h
...
root@master:~/lab2/cicd_samplecode# kubectl get pod -o wide
NAME                                             READY   STATUS    RESTARTS   AGE     IP                NODE      NOMINATED NODE   READINESS GATES
jenkins-6f46869d7b-msbw9                         2/2     Running   2          35m     192.168.219.73    master    <none>           <none>
netshoot                                         1/1     Running   1          4d6h    192.168.189.68    worker2   <none>           <none>
...
```
![image](https://user-images.githubusercontent.com/93571332/200517113-98f4da8b-dcdf-4869-8f91-97c3e475fce8.png)
