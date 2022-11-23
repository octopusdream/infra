### Horizontal Pod Autoscaling

`Horizontal Pod Autoscaling`(이하 HPA)은 워크로드 리소스(Deployment, Statefulset)를 자동으로 업데이트하며 워크로드의 크기를 수요에 맞게 자동으로 스케일링하는 것을 목표로 한다.

HPA는 쿠버네티스 api resource  및 컨트롤러 형태로 구현되어 있다.

- HPA api resource는 컨트롤러의 행동을 결정한다.
- HPA 컨트롤러는 control plane 내에서 실행되며, 평균 CPU, 메모리 사용률 또는 커스텀 메트릭 등의 메트릭을 목표에 맞추기 위해 target 리소스의 적정 크기를 주기적으로 조정한다.

### 작동 방식

![hpa](https://user-images.githubusercontent.com/59433441/203480670-ea9456e9-c854-4405-8be4-48ee3878b0aa.png)

[출처] [https://nirsa.tistory.com/187](https://nirsa.tistory.com/187)

HPA는 지속적으로 실행되는 것이 아닌 간헐적으로 실행되는 control loop 형태로 작동한다.

실행 주기는 `kube-controller-manager`의 `horizontal-pod-autoscaler-sync-period` 파라미터에 의해 설정된다.(기본값 15초)

각 주기마다 controller manager는 HPA에 지정된 메트릭에 대해 리소스 사용률을 질의한다.

controller manager는 `scaleTargetRef`에 의해 정의된 target 리소스를 찾은 뒤 리소스의 `.spec.selector` 레이블을 보고 파드를 선택하며, 리소스 메트릭 API(파드 단위 리소스 메트릭) 또는 커스텀 메트릭 API(그 외 모든 메트릭)로부터 메트릭을 수집한다.

파드 단위 리소스 메트릭의 경우 컨트롤러는 HPA가 대상으로 하는 각 파드에 대한 리소스 메트릭  API로부터 메트릭을 가져온다.

목표 사용률(`targetAverageUtilization`)이 설정되면 컨트롤러는 각 파드의 컨테이너에 대한 자원 요청을 퍼센트 단위로 하여 사용률 값을 계산한다.(target raw value가 설정된 경우 raw value를 직접 이용한다.)

컨트롤러는 모든 대상 파드에서 사용된 사용률을 계산한 뒤 사용률의 평균 또는 raw value를 가져와서 원하는 레플리카의 개수를 스케일하는데 사용되는 비율을 생성한다.

오브젝트 메트릭 및 외부 메트릭의 경우 오브젝트를 표현하는 단일 메트릭을 가져온 뒤 목표 값(`targetAverageValue`)과 비교하여 위와 같은 비율을 생성한다.

> HPA를 사용하는 일반적인 방법은 API(`metrics.k8s.io`, `custom.metrics.k8s.io`, `external.metrics.k8s.io`)로부터 메트릭을 가져오도록 설정하는 것이다.
> `metrics.k8s.io` API는 보통 메트릭 서버라는 애드온에 의해 제공되며, 메트릭 서버는 별도로 실행해야 한다.

```yaml
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-test
spec:
  minReplicas: 1  # 최소 replicas 개수
  maxReplicas: 5  # 최대 replicas 개수
  metrics:
  - resource:
      name: cpu  # HPA를 구성할 리소스(CPU, MEM 등)
      targetAverageUtilization: 60  # CPU 사용률이 60% 이상일 경우 생성
    type: Resource  # 리소스 타입 선언
  scaleTargetRef:  # 스케일 아웃할 타겟 설정
    apiVersion: apps/v1
    kind: Deployment  #  스케일 아웃할 타겟의 종류 (deployment, replicaset 등)
    name: nginx-deploy  #  스케일 아웃할 타겟의 네임
```

### 알고리즘

HPA 컨트롤러는 원하는 메트릭 값과 현재 메트릭 값 사이의 비율로 작동한다.

> 원하는 레플리카 수 = ceil[현재 레플리카 수 * (현재 메트릭 값 / 원하는 메트릭 값)]

현재 메트릭 값이 `200m`이고 원하는 값이 `100m`인 경우 `200.0 / 100.0 == 2.0`이므로 레플리카 수가 두 배가 된다.

현재 메트릭 값이 `50m`이고 원하는 값이 `100m`인 경우 `50.0 / 100.0 == 0.5`이므로 레플리카 수를 반으로 줄인다.

비율이 1.0에 가깝다면 control plane은 스케일링을 진행하지 않는다.

### API 오브젝트

HPA는 쿠버네티스 `autoscaling` API 그룹의 api resource이다.

현재 안정 버전은 `autoscaling/v2`이며 메모리와 커스텀 메트릭에 대한 스케일링을 지원한다.

### 리소스 메트릭

모든 HPA 대상은 스케일링 대상에서 파드의 리소스 사용량을 기준으로 스케일링할 수 있다.

파드 spec을 정의할 때는 `cpu` 및 `memory`와 같은 리소스 요청을 지정해야 한다.

지정한 리소스는 리소스 사용률을 결정하는 데 사용되며 HPA 컨트롤러에서 대상을 스케일링하거나 축소하는 데 사용한다.

리소스 사용률 기반 스케일링을 사용하려면 다음과 같은 메트릭 소스를 지정해야 한다.

```yaml
type: Resource
resource:
  name: cpu
  target:
    type: Utilization
    averageUtilization: 60
```

이 메트릭을 사용하면 HPA 컨트롤러는 스케일링 대상에서 파드의 평균 사용률을 60%로 유지한다.

사용률은 파드의 요청된 리소스에 대한 현재 리소스 사용량 간의 비율이다.

### 컨테이너 리소스 메트릭

HPA API는 대상 리소스를 스케일링하기 위해 파드 집합에서 개별 컨테이너의 리소스 사용량을 추적할 수 있는 컨테이너 메트릭 소스도 지원한다.

이를 통해 특정 파드에서 중요한 컨테이너의 스케일링 임계값을 구성할 수 있다.

(파드 내에 애플리케이션 컨테이너와 로깅 사이드카가 있는 경우 사이드카 컨테이너와 해당 리소스 사용을 무시하고 애플리케이션의 리소스 사용을 기준으로 스케일링 가능)

메트릭 소스에 지정된 컨테이너가 없거나 파드의 하위 집합에만 있는 경우 해당 파드는 무시되고 권장 사항이 다시 계산된다.

컨테이너 리소스를 오토스케일링에 사용하려면 다음과 같이 메트릭 소스를 정의한다.

```yaml
type: ContainerResource
containerResource:
  name: cpu
  container: application
  target:
    type: Utilization
    averageUtilization: 60
```

HPA 컨트롤러는 모든 파드의 `application` 컨테이너에 있는 CPU 평균 사용률이 60%가 되도록 대상을 조정한다.

### 복수 메트릭 이용

`autoscaling/v2` API 버전을 사용하는 경우 HPA는 스케일링에 사용할 복수의 메트릭을 설정할 수 있다.

복수 메트릭을 이용할 경우 HPA 컨트롤러는 각 메트릭을 확인하고 해당 메트릭에 대한 새로운 스케일링을 제안한다.

HPA는 새롭게 제안된 스케일링 크기 중 가장 큰 값을 선택하여 워크로드의 크기를 조정한다.

### kubectl를 통한 HPA 조작

HPA는 모든 API 리소스와 마찬가지로 `kubectl`에 의해 표준 방식으로 지원된다,

- `kubectl create hpa` : 오토스케일러 생성
- `kubectl get hpa` : 오토스케일러 목록 조회
- `kubectl describe hpa` : 오토스케일러 세부 사항 확인
- `kubectl delete hpa` : 오토스케일러 삭제

`kubectl autoscale` 명령을 이용하여 HPA를 생성할 수도 있다.

```bash
# 레플리카셋 foo에 대한 오토스케일러 생성, 목표 cpu 사용률은 80%이며 2와 5사이의 크기를 갖는다.
kubectl austoscale rs foo --min=2 --max=5 --cpu-percent=80
```