AWS EC2를 이용하여 쿠버네티스 클러스터를 구축할 경우 해당 클러스터가 AWS 환경에서 동작하고 있음을 알게 하기 위해서는 별도의 작업이 필요하다.

이 작업을 통해 API를 이용하여 별도의 작업 없이 클러스터 상에서 AWS의 서비스(ELB, EBS 등등)을 이용할 수 있다.

테스트 환경은 다음과 같다.

- Kubernetes v1.21.1
- Docker v20.10.21

### EC2 hostname 설정

AWS의 private DNS를 사용할 수 있도록 인스턴스의 hostname을 다음과 같이 변경한다.

`ip-xxx-xxx-xxx-xxx.<region>.compute.internal`

다음 명령을 이용하면 간편하게 설정할 수 있다.

```bash
$ sudo hostnamectl set-hostname \
$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

$ hostname
ip-10-0-3-xxx.ap-northeast-2.compute.internal
```

### IAM 정책, 역할 생성해서 EC2 연결

인스턴스가 AWS 서비스를 이용할 수 있도록 정책을 생성한 뒤, 역할을 만들어 인스턴스에 연결한다.

마스터 노드가 수행하는 일이 더 많으므로 더 많은 정책이 필요하다.

- master 노드
    
    ```bash
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVolumes",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:ModifyInstanceAttribute",
            "ec2:ModifyVolume",
            "ec2:AttachVolume",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateRoute",
            "ec2:DeleteRoute",
            "ec2:DeleteSecurityGroup",
            "ec2:DeleteVolume",
            "ec2:DetachVolume",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DescribeVpcs",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:AttachLoadBalancerToSubnets",
            "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancerPolicy",
            "elasticloadbalancing:CreateLoadBalancerListeners",
            "elasticloadbalancing:ConfigureHealthCheck",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteLoadBalancerListeners",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DetachLoadBalancerFromSubnets",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancerPolicies",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
            "iam:CreateServiceLinkedRole",
            "kms:DescribeKey"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
    ```
    
- worker 노드
    
    ```bash
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage"
          ],
          "Resource": "*"
        }
      ]
    }
    ```
    

역할을 생성했으면 인스턴스에 연결한다.

![ec2-role](https://user-images.githubusercontent.com/59433441/203196186-3c34cee4-0e07-4e36-ace1-9474ae234a78.png)

### 태그 등록

`AWS Cloud Provider`가 인식할 수 있도록 해당 리소스에 다음과 같은 태그를 붙여야 한다.

태그를 붙이지 않으면 리소스를 인식하지 못하여 `kubeadm init` 시에 오류가 발생한다.

먼저 태그에는 두 가지 속성이 있다.

- `kubernetes.io/cluster/<your_cluster_id>: owned` : 리소스가 클러스터에 의해 소유되고 관리되는 경우
- `kubernetes.io/cluster/<your_cluster_id>: shared` : 리소스가 여러 클러스터 간에 공유되고, 클러스터가 삭제되어도 유지되어야 하는 경우

아래 리소스에 해당하는 태그를 붙인다.

- Instance
    - `kubernetes.io/cluster/<your_cluster_id>: owned|shared`
- Subnet
    - Public Subnet : `kubernetes.io/role/elb: 1`
    - Private Subnet : `kubernetes.io/role/internal-elb: 1`
    - 모든 Subnet : `kubernetes.io/cluster/<your_cluster_id>: owned|shared`
- Routing Table
    - Cloud Controller Manager가 `--configure-cloud-routes: "false"` 옵션으로 시작되지 않는 경우 Subnet처럼 태그를 지정
- Security Group
    - `kubernetes.io/cluster/<your_cluster_id>: owned|shared`

### Configuration 파일 적용

`kubeadm`을 이용하여 클러스터를 구축하는 경우 configuration 파일에 `cloud-provider` 옵션을 추가해야 한다.

3가지 경우에 맞게 configuration 파일을 적용한다.

- control plane 생성
    
    ```yaml
    # control-plane.yaml
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
        cloud-provider: aws  # cloud-provider 옵션 추가
      timeoutForControlPlane: 4m0s
    certificatesDir: /etc/kubernetes/pki
    clusterName: <cluster-name>  # 태그에 지정할 클러스터 이름을 명시
    controlPlaneEndpoint: "Endpoint:포트번호"  # HA 구성 시 <LB Endpoint:포트번호>
    controllerManager:
      extraArgs:
        cloud-provider: aws  # cloud-provider 옵션 추가
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: k8s.gcr.io
    
    networking:
      dnsDomain: cluster.local
      podSubnet: 192.168.0.0/16
      serviceSubnet: 10.96.0.0/12
    scheduler: {}
    ---
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        cloud-provider: aws  # cloud-provider 옵션 추가
    ```
    
    아래와 같은 명령으로 configuration 파일을 적용한다.
    
    ```bash
    $ kubeadm init --config control-plane.yaml
    ```
    
    만약 HA를 구성한다면 다음 명령을 사용한다.
    
    ```bash
    $ kubeadm init --config control-plane.yaml --upload-certs
    ```
    
- HA를 위해 다수의 control plane을 이용
    
    ```yaml
    # control-plane-join.yaml
    apiVersion: kubeadm.k8s.io/v1beta3
    kind: JoinConfiguration
    discovery:
      bootstrapToken:
        token: 123456.a4v4ii39rupz51j3  # token 값
        apiServerEndpoint: "cp-lb.us-west-2.elb.amazonaws.com:6443"  # 엔드포인트로 사용할 LB는 미리 생성
        caCertHashes: ["sha256:193feed98fb5fd2b4974..."]  # hash 값
    nodeRegistration:
      name: ip-10-0-4-xxx.ap-northeast-2.compute.internal  # 등록할 control-plane hostname
      kubeletExtraArgs:
        cloud-provider: aws  # cloud-provider 옵션 추가
    controlPlane:
      localAPIEndpoint:
        advertiseAddress: 10.0.4.xxx
      certificateKey: "f6fcb672782d6f0581a106..."  # kubeadm init 이후 출력된 certificate key
    ```
    
    아래와 같은 명령으로 configuration 파일을 적용한다.
    
    ```bash
    $ kubeadm join --config control-plane-join.yaml
    ```
    
- worker 노드 join
    
    ```yaml
    # worker.yaml
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: JoinConfiguration
    discovery:
      bootstrapToken:
        token: 123456.a4v4ii39rupz51j3 # token 값
        apiServerEndpoint: "10.0.3.xxx:6443" # HA가 구축되지 않은 경우, HA가 구축된 경우 LB 엔드포인트 사용
        caCertHashes:
          - sha256:193feed98fb5fd2b4974... # hash 값
    nodeRegistration:
      name: ip-10-0-3-xxx.ap-northeast-2.compute.internal # worker hostname
      kubeletExtraArgs:
        cloud-provider: aws  # cloud-provider 옵션 추가
    ```
    
    아래와 같은 명령으로 configuration 파일을 적용한다.
    
    ```bash
    $ kubeadm join --config worker.yaml
    ```
    

### AWS Controller Manager

control plane을 init 했다면 `AWS Controller Manager` 매니페스트 파일을 실행해야 한다.

```bash
# kustomize 설치
$ wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.6/kustomize_v4.5.6_linux_amd64.tar.gz
$ gzip -d kustomize_v4.5.6_linux_amd64.tar.gz
$ tar xvf kustomize_v4.5.6_linux_amd64.tar
$ mv ./kustomize  /usr/bin

# 매니페스트 파일 설치
$ kustomize build 'github.com/kubernetes/cloud-provider-aws/examples/existing-cluster/overlays/superset-role/?ref=master' | kubectl apply -f -
```

### CNI 플러그인 설치

클러스터에서 사용할 CNI 플러그인을 설치한다.

테스트 환경에서는 Calico를 설치하였다.

```bash
$ kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 결과

위 작업을 모두 완료하면 성공적으로 클러스터가 구축된 것을 확인할 수 있다.

```bash
$ kubectl get nodes
NAME                                            STATUS   ROLES                  AGE    VERSION
ip-10-0-3-xxx.ap-northeast-2.compute.internal   Ready    control-plane,master   16m    v1.21.1
ip-10-0-3-xxx.ap-northeast-2.compute.internal   Ready    <none>                 13m    v1.21.1
ip-10-0-3-xxx.ap-northeast-2.compute.internal   Ready    <none>                 2m4s   v1.21.1
```

### 테스트

AWS 서비스를 정상적으로 이용할 수 있는지 간단한 테스트를 진행하였다.

테스트용 Deployment와 Service를 배포한다.

```yaml
# nginx-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
          - name: http
            containerPort: 80
```

```yaml
# nginx-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  ports:
  - name: http
    port: 80
  selector:
    app: nginx
  type: LoadBalancer
```

정상적으로 AWS의 LB가 생성됨을 확인할 수 있다.

```bash
$ kubectl get svc
NAME                                  TYPE           CLUSTER-IP       EXTERNAL-IP                                                                          PORT(S)        AGE
kubernetes                            ClusterIP      10.96.0.1        <none>                                                                               443/TCP        2d15h
nginx-service                         LoadBalancer   10.108.29.182    a9524dcbe2481446689a580b9face799-bbd01611be30a1f7.elb.ap-northeast-2.amazonaws.com   80:31905/TCP   114s
```