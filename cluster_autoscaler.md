## Cluster Autoscaler on AWS

Cluster Autoscaler(이하 CA)는 노드 그룹을 관리하기 위해 Auto Scaling Group(이하 ASG)를 이용한다.

CA는 클러스터에서 `Deployment` 오브젝트로 실행된다.

### CA 배포하기

1. YAML 파일을 다운로드 한다.
    
    ```bash
    $ curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    ```
    
2. YAML 파일을 수정하고 *`<YOUR CLUSTER NAME>`*을 클러스터 이름으로 바꾼다.
3. YAML 파일을 클러스터에 적용한다.
    
    ```bash
    $ kubectl apply -f cluster-autoscaler-autodiscover.yaml
    ```
    
4. `cluster-autoscaler.kubernetes.io/safe-to-evict` annotation을 파드에 추가한다.
    
    ```bash
    $ kubectl patch deployment cluster-autoscaler \
      -n kube-system \
      -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
    ```
    
5. 수정 사항을 적용한다.
    
    ```bash
    $ kubectl -n kube-system edit deployment.apps/cluster-autoscaler
    ```
    
6. 필요한 옵션들을 추가한다.
    - `--balance-similar-node-groups`
    - `--skip-nodes-with-system-pods=false`
    
    ```yaml
        ...
        spec:
          containers:
          - command
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/my-cluster
            - --balance-similar-node-groups
            - --skip-nodes-with-system-pods=false
    ```
    
7. 다음 명령을 통해 CA 로그를 확인할 수 있다.
    
    ```bash
    $ kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
    ```
    

### CA의 권한

CA는 ASG를 조작할 수 있어야 한다.

AWS는 이를 위해 IAM roles를 생성하여 SA(Service Account)에 연결한 후 CA Deployment가 해당 SA를 이용하여 배포하도록 권장하고 있다.

만약 IAM roles와 SA를 함께 사용할 수 없을 경우 CA 파드가 실행되고 있는 인스턴스에 IAM service role을 부여해야 한다.

### IAM 정책

CA에 IAM 권한을 주는 방법은 두 가지가 있으며 적절한 범위의 권한을 주는 것이 중요하다.

AWS는 정책의 리소스 목록에서 ASG ARN을 지정하거나 태그를 사용하여 Autoscaling 작업의 대상 리소스를 제한하는 것을 권고하고 있다.

**Full Cluster Autoscaler Features Policy (Recommended)**

`ASG AutoDiscovery`와 동적으로 EC2 목록을 가져올 때(기본값) 사용하는 권한

```yaml
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    }
  ]
}
```

**Minimal IAM Permissions Policy**

CA를 실행하는데 필요한 최소 권한

`ASG AutoDiscovery`를 사용할 수 없으며, 해당 정책을 사용할 경우 CA에 인자로 최소 및 최대 노드 수와 ASG를 전달해야 한다.

```yaml
--aws-use-static-instance-list=false
--nodes=1:100:exampleASG1
--nodes=1:100:exampleASG2
```

```yaml
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["arn:aws:autoscaling:${YOUR_CLUSTER_AWS_REGION}:${YOUR_AWS_ACCOUNT_ID}:autoScalingGroup:*:autoScalingGroupName/${YOUR_ASG_NAME}"]
    }
  ]
}
```

### ****AWS Credentials 사용 방법****

Kubernetes Secrets를 활용하여 CA 매니페스트 파일에 환경 변수로 IAM 자격 증명을 제공할 수 있다.

CA는 해당 자격 증명을 사용하여 자체적으로 인증하고 권한을 부여한다.

```yaml
# aws-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-secret
type: Opaque
data:
  aws_access_key_id: BASE64_OF_YOUR_AWS_ACCESS_KEY_ID
  aws_secret_access_key: BASE64_OF_YOUR_AWS_SECRET_ACCESS_KEY
```

```yaml
# ClusterAutoscaler.yaml
...
env:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: aws-secret
        key: aws_access_key_id
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: aws-secret
        key: aws_secret_access_key
  - name: AWS_REGION
    value: YOUR_AWS_REGION
```

### AutoDiscovery 설정

CA가 자동으로 타겟 ASG를 인식하도록 설정하는 방법

AutoDiscovery를 활성화하기 위해서는 `--node-group-auto-discovery` 플래그에 찾고자 하는 태그 리스트를 인자로 제공해야 한다.

예를 들어 `--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<cluster-name>`를 사용할 경우 해당 태그를 갖고 있는 ASG를 AutoDiscovery 한다.

[cluster-name 등록하는 방법](https://stackoverflow.com/questions/38242062/how-to-get-kubernetes-cluster-name-from-k8s-api)

태그가 없으면 CA는 ASG를 찾을 수 없기 때문에 새 인스턴스를 추가할 수 없다.

태그 값을 사용 가능하도록 설정할 수 있으며 사용자 정의 태그도 추가할 수 있다.

`--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled=foo,k8s.io/cluster-autoscaler/<cluster-name>=bar,my-custom-tag=custom-value`

CA는 각 ASG의 최소 노드 수와 최대 노드 수 안에서 노드 수를 조정한다.

각 ASG는 비슷한 용량의 인스턴스 유형으로 구성되어야 한다.

```markdown
xlarge를 사용할 경우 : m5a.xlarge, m4.xlarge, m5.xlarge로 구성
2xlarge를 사용할 경우 : m5a.2xlarge, m4.2xlarge, m5.2xlarge로 구성
```

CA는 `Launch Configuration` 또는 `Launch Template`에 지정된 인스턴스 타입을 기반으로 ASG에서 제공하는 CPU, 메모리 및 GPU 리소스를 결정한다.

또한 `ASG’s Mixed Instances Policy`에 있는 overrides를 검사한다.

만약 overrides가 발견되면 발견된 첫 번째 인스턴스 유형이 사용된다.

CA는 파드의 nodeSelector, toleration을 기반으로 desired 값을 증가시킬 ASG를 찾는다.

ASG가 Launch Configurations 또는 Launch Templates을 사용하는 경우 CA가 사용하는 IAM 정책에  `autoscaling:DescribeLaunchConfigurations`

또는 `ec2:DescribeLaunchTemplateVersions` 항목을 반드시 추가해야 한다.

### Manual configuration

CA는 `--nodes` 인자를 사용하여 수동으로 설정할 수 있다.

`--nodes=<min>:<max>:<asg-name>`

`--nodes` 인자를 여러 번 사용하여 CA가 사용할 여러 개의 ASG 설정도 가능하다.

`<min>`과 `<max>`는 ASG에 포함되는 값을 사용해야 한다.

CA 파드를 마스터 노드에서 실행시키기 위해서는 `taint`와 `nodeSelector`를 이용하면 된다.

### CA는 어떻게 동작할까?

CA는 파드를 스케줄할 수 있는 노드가 없을 때 노드를 추가한다.

클러스터에 존재하는 노드와 비슷한 노드를 추가하는 것이 좋다.

CA는 노드가 필요하지 않을 때 노드를 제거한다.

### CA로부터 보호되는 파드

아래의 파드들은 CA에 의해 노드가 draining될 때 보호된다.

- `PodDisruptionBudget`(이하 PDB)가 설정된 파드
    - [PDB](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)는 인위적인 노드 다운과 같이 volutary disruption 상황에도 항상 최소한의 파드 수를 유지하도록 해준다.
- kube-system 파드
- controller에 의해 baked 되지 않는 파드
    - Deployment, ReplicaSet, Job, StatefulSet 등에 의해 생성되지 않은 파드
- 로컬 스토리지를 사용하는 파드
- 제약으로 인해 다른 곳으로 이동할 수 없는 파드
    - 리소스 부족
    - nodeSelector에 매칭되는 노드가 없을 때
    - nodeAffinity에 매칭되는 노드가 없을 때
- `"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"` annotation이 설정된 파드
- `"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"` annotation이 없는 파드

### Horizontal Pod Autoscaler와 함께 사용

`Horizontal Pod Autoscaler`(이하 HPA)는 현재 CPU 부하를 기준으로 Deployment, ReplicaSet의 replica 수를 변경한다.

CPU 부하가 증가하면 HPA는 클러스터에 충분한 리소스 여부에 관계없이 새로운 replicas를 생성한다.

리소스가 충분하지 않은 경우 CA는 HPA가 파드를 생성할 수 있도록 새로운 노드를 추가한다.

부하가 감소하면 HPA는 replicas를 줄이게 되고, 몇몇 노드들은 활용도가 낮거나 비게 된다.

CA는 이러한 불필요한 노드를 종료한다.

### CPU 사용량 기반 노드 autoscaler와의 차이점

CA는 CPU 부하 여부에 관계없이 파드가 실행될 수 있는지를 확인한다.

또한 클러스터에 불필요한 노드가 없는지 확인한다.

CPU 사용량 기반(또는 메트릭 기반) autoscaler는 scale in/out 할 때 파드를 신경쓰지 않는다.

파드가 없는 노드를 추가할 수 있고, 중요한 파드가 있는 노드를 제거할 수 있다.

쿠버네티스와 이런 autoscaler를 함께 사용하는 것은 권장되지 않는다.

CA와도 함께 사용하지 않는 것이 좋다.

### multiple zone에서의 CA

v0.6부터 지원한다.

`--balance-similar-node-groups` 플래그를 true로 설정하면 CA는 동일한 인스턴스 유형과 동일한 레이블 셋을 가진 노드 그룹을 자동으로 식별하고 해당 노드 그룹의 크기를 balancing한다.

현재는 scale out 시에만 balancing한다.(향후에 scale in에도 적용할 예정이라고 한다.)

CA는 기존 파드를 실행하는 데 필요한 만큼만 노드를 추가한다.

노드 수가 balanced node group의 수로 딱 나눠지지 않을 때는 몇몇 그룹은 1개 더 많은 노드를 갖고 있을 수 있다.

만약 파드가 단일 노드 그룹으로만 이동할 수 있는 경우(nodeSelector를 사용하는 경우) CA는 특정 노드 그룹에만 노드를 추가한다.

노드 그룹에 사용자 지정 레이블을 지정하여 동일한 인스턴스 유형을 사용하는 다른 노드 그룹과 자동으로 balancing되지 않도록 할 수 있다.

### CA의 이벤트 확인

`--record-duplicated-events` 플래그를 사용하여 CA의 이벤트를 확인할 수 있다.

### 특정 노드를 scale down으로부터 보호하는 방법

v1.0부터 해당 annotation이 있으면 CA의 scale down으로부터 제외된다.

`"cluster-autoscaler.kubernetes.io/scale-down-disabled": "true"`

다음 명령을 사용하여 annotation을 추가할 수 있다.

```bash
$ kubectl annotate node <nodename> cluster-autoscaler.kubernetes.io/scale-down-disabled=true
```

### Overprovisioining

v1.1부터 overprovisioning 기능을 사용할 수 있다.

노드가 scale out 되는 시간을 절약하기 위해 일정 갯수만큼의 인스턴스를 미리 overprovisioning 해 놓을 수 있다.

매우 낮은 우선 순위로 pause 파드를 배포하여 overprovisioning을 설정할 수 있다.

리소스가 충분하지 않으면 pause 파드는 선점되고 새 파드가 위치하게 된다.

생성되는 pause 파드는  스케줄 할 수 없기 때문에 CA가 scale out하게 한다.

overprovisioning의 크기는 pause 파드의 크기와 replicas를 조절하여 제어할 수 있다.

동적으로 크기를 변경하려면 pause 파드 수를 변경하는 HPA를 사용해야 한다.

### scale out 동작 방식

CA는 apiserver를 감시하여 10초(`--scan-interval` 플래그로 설정 가능)마다 unschedulable한 파드가 있는지 검사한다.

unschedulable한 파드가 있다면 CA는 노드 그룹에 노드를 생성하고 해당 파드를 실행한다.

CA는 최대 15분(`--max-node-provision-time` 플래그로 설정 가능)까지 요청된 노드가 생성되기를 기다리고 노드가 생성되지 않은 경우 다른 그룹에 노드를 생성한다. 

생성한 노드를 클러스터에 join 시키기 위해 스크립트를 통해 `kubeadm join` 명령을 실행해야 한다.

### scale in 동작 방식

CA는 10초(`--scan-interval` 플래그로 설정 가능)마다 필요 없는 노드가 있는지 검사한다.

필요 없는 노드는 아래의 조건을 모두 만족해야 한다.

- 노드에서 실행 중인 모든 파드의 CPU, 메모리 합계가 노드 리소스의 50%보다 작은 경우
- 실행되는 모든 파드들이 다른 노드로 이동할 수 있는 경우
- scale-down annotaion이 비활성화 되어 있는 경우

노드가 10분 이상 필요 없는 상태를 유지하면 제거된다.

CA는 비어 있지 않은 노드는 한 번에 하나씩 종료하고 비어 있는 노드는 한 번에 최대 10개까지 종료할 수 있다.(`--max-empty-bulk-delete` 플래그 사용)

비어 있지 않은 노드들에 있던 파드들은 다른 노드로 마이그레이션 해야 하는데 만약 적절한 노드가 없다면 다시 스케줄 되지 않을 수 있다.

### scale in에서의 GracefulTermination

v1.0부터 최대 10분(기본값)동안 파드의 GracefulTermination을 지원하며 `--max-grace-termination-sec` 플래그를 이용하여 값을 변경할 수 있다.

파드가 설정한 시간 이내에 종료되지 않아도 노드는 종료된다.

### expander

CA는 스케줄 할 수 없는 파드로 인해 scale out을 식별하면 일부 노드 그룹의 노드의 수를 늘린다.

노드 그룹이 하나인 경우는 간단하지만 노드 그룹이 두 개 이상인 경우 확장할 노드 그룹을 결정해야 한다.

expander는 새 노드가 추가될 노드 그룹을 선택하기 위한 옵션을 제공한다.

- `random` : 무작위로 노드 그룹 선택
- `most-pods` : 가장 많은 파드를 스케줄 할 수 있는 노드 그룹 선택
- `least-waste` : pod가 할당되었을 때 CPU와 메모리가 가장 적게 남는 노드 그룹 선택
- `price` : GCE, GKE에서만 사용 가능한 옵션으로 pod를 생성했을 때 비용이 가장 낮게 나오는 노드 그룹 선택
- `priority` : 사용자가 설정한 우선순위가 가장 높은 노드 그룹 선택

`--expander` 플래그를 사용하여 설정할 수 있으며 기본값은 `random`이다.

```bash
$ ./cluster-autoscaler --expander=random
```

v1.23.0부터 여러 expander를 사용할 수 있다.

```bash
 $ ./cluster-autoscaler --expander=priority,least-waste
```

### CA와 nodeAffinity

CA는 노드 그룹에 지정된 nodeAffinity의 `nodeSelector`와 `requiredDuringSchedulingIgnoredDuringExecution`을 지원한다.

위 설정을 만족하는 파드를 스케줄 할 수 없는 경우 CA는 해당 노드 그룹을 scale out 한다.

하지만 CA는 `preferredDuringSchedulingIgnoredDuringExecution`과 같은 soft한 제약 조건은 고려하지 않는다.

즉, CA에 확장 가능한 노드 그룹이 두 개 이상 있는 경우 확장할 노드 그룹을 선택할 때 soft 제약 조건은 무시된다.

### CA에 사용 가능한 parameter

사용 가능한 파라미터 목록은 [링크](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca)에서 확인할 수 있다.

### Notes

EKS를 사용하지 않고 OS로 Amazon Linux 2를 사용하지 않는다면 CA 매니페스트 파일의 볼륨 hostPath에 `/etc/ssl/certs/ca-certificates.crt`를 사용하거나 올바른 호스트 경로를 사용해야 한다.

```yaml
# https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml			
    ...				
    volumeMounts:
      - name: ssl-certs
        mountPath: /etc/ssl/certs/ca-certificates.crt #/etc/ssl/certs/ca-bundle.crt for Amazon Linux Worker Nodes
        readOnly: true
   volumes:
    - name: ssl-certs
      hostPath:
        path: "/etc/ssl/certs/ca-certificates.crt"
```

기본적으로 CA는 scale down 작업 사이에 10분을 기다리며(파드의 GracefulTermination을 위해), `--scale-down-delay-after-add`, `--scale-down-delay-after-delete`, `--scale-down-delay-after-failure` 플래그를 이용하여 시간을 조정할 수 있다.

`--scale-down-delay-after-add=5m` → scale down delay를 5분으로 줄인다.

EKS를 사용하지 않는 경우 ASG에 `eks:nodegroup-name` 태그를 사용해서는 안된다.

위 태그를 사용한다면 노드 그룹에 노드가 0개일 때 부가적인 EKS API를 호출하여 스케일링 속도가 저하될 수 있다.

---

참고

- https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md

- https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-key-best-practices-for-running-cluster-autoscaler

- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/autoscaling.html
