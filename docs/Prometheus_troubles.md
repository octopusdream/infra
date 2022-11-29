# Issue: Node Exporter down

<img width="1433" alt="image" src="https://user-images.githubusercontent.com/28949162/204507614-f9bf5145-9c56-4e89-8f6e-77bbc1cff6fb.png">

인스턴스가 모두 작동중임에도 불구하고 node-exporter가 다운 되있다.

<img width="840" alt="image" src="https://user-images.githubusercontent.com/28949162/204508168-7d8254ad-7447-47f5-b8e6-31300028ef60.png">

pod status == Ready 상태이지만, 그라파나 대시보드에서 확인할 수 없고, 프로메테우스 서버에서 조회가 불가능하다. 마스터 node-exporter를 제외한 worker 노드들 전부 node-exporter가 정상 작동하지 않는다.

```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  11s   default-scheduler  0/4 nodes are available: 1 node(s) didn't have free ports for the requested pod ports, 3 node(s) didn't match Pod's node affinity/selector.
  Warning  FailedScheduling  10s   default-scheduler  0/4 nodes are available: 1 node(s) didn't have free ports for the requested pod ports, 3 node(s) didn't match Pod's node affinity/selector.
  Normal   Scheduled         8s    default-scheduler  Successfully assigned default/prometheus-prometheus-node-exporter-544xt to ip-10-0-3-139.ap-northeast-2.compute.internal
```

Node exporter 를 제외한 나머지 컴포넌트는 제대로 작동한다 어떤게 문제일까?

curl localhost:9100/metrics 를 각 노드에서 하면 결과 값 확인 가능한 상황

1. SD
2. 

# grafana 비밀번호 오류

helm re install 시
--set adminPassword="admin" 해줘도 비밀번호 에러가 뜸 

![](https://velog.velcdn.com/images/hyunshoon/post/5ce14fa2-35e9-4134-a6f9-42780af16636/image.png)

이전에 설치했을 때 비밀번호를 변경해주었는데, helm 으로 재설치하면 비밀번호가 초기화 되는게 아니라 이전에 변경한 비밀번호로 저장되어있음.

# grafana readiness probe failed

![](https://velog.velcdn.com/images/hyunshoon/post/d9d9c449-408b-4e80-8a12-f7e900979292/image.png)

며칠 뒤 재배포를 해봤는데 그라파나 대시보드 연결만 되고 소스를 가져오지 못하는 문제가 있다.

```shell
  Normal   Started    9m43s                  kubelet            Started container grafana
  Warning  Unhealthy  9m42s (x2 over 9m43s)  kubelet            Readiness probe failed: Get "http://192.168.161.59:3000/api/health": dial tcp 192.168.161.59:3000: connect: connection refused

```

바뀐 환경이 뭐가있을까 생각해보면 며칠사이 그라파나 헬름 차트 버전 업그레이드가 있다.

![](https://velog.velcdn.com/images/hyunshoon/post/8dd02290-07f8-4984-915f-0ae366151a7d/image.png)

따라서, 기존에 --set 으로 overwrite 하는것을 values.yaml 파일을 고쳐쓰는 방법으로 바꿔본다.

바꾼 values.yaml 파일은 github 에 첨부

```shell
helm install grafana grafana/grafana \
--set persistence.enabled=true \
--set persistence.existingClaim=grafana \
--set service.type=LoadBalancer \ #c
--set securityContext.runAsUser=1000 \ #c
--set securityContext.runAsGroup=1000 \ #c
--set adminPassword="admin" \ #check
```

![](https://velog.velcdn.com/images/hyunshoon/post/f405567e-4bff-4c1b-a2ab-098e28f51896/image.png)


```
helm install grafana ./grafana
```

하지만, 여전히 readinessProbe error 가 뜨며 데이터를 받아오지 못한다.



## Ouch!
![](https://velog.velcdn.com/images/hyunshoon/post/f13395c8-c5b6-45ee-9ac8-c9c60dd26dd3/image.png)

절약을 위해 개발하지 않을 때 인스턴스를 내리고, 프로메테우스도 내리기 때문에 다시 올릴 때 Cluster IP 가 바뀐다는걸 까먹지 말자. 위 IP 를 현재 프로메테우스 IP로 바꿔주면 된다.

버전 탓 부터 하는 내 사고방식을 손 볼 필요가 있다 🤷‍♂️ 

# webhook trouble - Config reload

임의로 노드를 다운시켜봤는데, prometheus server에서는 얼럿이 잘 가는데 슬랙으로 웹훅은 또 안된다. 🤦‍♂️

또 웹훅 url이 이전에 설정한 것과 달라져있다. 바뀐 URL을 변경해야한다.

프로메테우스 설정을 바꿀 때 prometheus를 재설치 하는 방법말고 다른 방도가 있을 것이다.

공식문서에 따르면 프로메테우스는 런타임중에 설정을 reload 할 수 있다. 
>
공식문서 내용
>
Prometheus can reload its configuration at runtime. If the new configuration is not well-formed, the changes will not be applied. A configuration reload is triggered by sending a SIGHUP to the Prometheus process or sending a HTTP POST request to the /-/reload endpoint (when the --web.enable-lifecycle flag is enabled). This will also reload any configured rule files.


공식문서에 따르면 프로메테우스는 런타임중에 설정을 reload 할 수 있다. 
>
Prometheus can reload its configuration at runtime. If the new configuration is not well-formed, the changes will not be applied. A configuration reload is triggered by sending a SIGHUP to the Prometheus process or sending a HTTP POST request to the /-/reload endpoint (when the --web.enable-lifecycle flag is enabled). This will also reload any configured rule files.


## How?

프로메테우스 컨피그맵을 수정후 재배포하면 된다.

```
kubectl get configmap ## configmap name 확인
kubectl get configmap -o yaml prometheus-alertmanager > prometheus_config.yaml
vi prometheus_config.yaml ### 수정할 부분 수정
```

![](https://velog.velcdn.com/images/hyunshoon/post/3df11406-3095-4f48-ac60-bc712c3b40aa/image.png)

기존 컨피그맵이다. 

receivers.slack_configs.text를 변경 후 재배포 해본다.

변경 후 apply
```shell
⚡ root@ip-10-0-3-181  ~/prometheus  k apply -f prometheus_config.yml
configmap/prometheus-alertmanager configured
```
## Test
configmap describ로 확인
```yaml
 ⚡ root@ip-10-0-3-181  ~/prometheus  k describe configmap prometheus-alertmanager
Name:         prometheus-alertmanager
Namespace:    default
Labels:       app=prometheus
              app.kubernetes.io/managed-by=Helm
              chart=prometheus-16.0.0
              component=alertmanager
              heritage=Helm
              release=prometheus
Annotations:  meta.helm.sh/release-name: prometheus
              meta.helm.sh/release-namespace: default

Data
====
allow-snippet-annotations:
----
false
alertmanager.yml:
----
global:
  slack_api_url: https://hooks.slack.com/services/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
receivers:
- name: slack-notifier
  slack_configs:
  - channel: '#k8s-monitoring'
    send_resolved: true
    text: For reload Test.Node has been down for more than 1 minute.
route:
  group_interval: 1m
  group_wait: 10s
  receiver: slack-notifier
  repeat_interval: 2m

Events:  <none>
```

logs로 확인
```shell
 ⚡ root@ip-10-0-3-181  ~/prometheus  k logs prometheus-alertmanager-585bf69d6d-pmvwg -c prometheus-alertmanager-configmap-reload
2022/11/27 04:25:02 Watching directory: "/etc/config"
2022/11/27 05:19:15 config map updated
2022/11/27 05:19:15 performing webhook request (1/1)
2022/11/27 05:19:15 successfully triggered reload
```
## webhook test
![](https://velog.velcdn.com/images/hyunshoon/post/c9fbf26b-0554-454e-b647-78c2a21c1f3e/image.png)

인스턴스 중지하여 슬랙 알람 테스트를 해본다.

![](https://velog.velcdn.com/images/hyunshoon/post/1a0e25d3-f136-4175-9eeb-bf276bdaf7ac/image.png)

Reference
- https://prometheus.io/docs/prometheus/latest/configuration/configuration/


