# Issue: Node down => Prometheus server can't access node-exporter metrics

## Summary

**노드는 모두 정상 작동중이지만, 1. prometheus alert rule에 의해 다운되어있다고 판별 2. 그라파나 대시보드로 마스터 노드를 제외한 나머지 노드들에 대한 정보를 알 수 없음**

특이사항: 이전 배포에서는 문제 된 적이 없었다. 다른 상황이라고는 다중가용영역에서 처음 배포라는 것. 하지만, 정상 작동하는 master node와 같은 zone에 있는 worker1도 스크랩 할 수 없는 상황을 고려하면 다중 가용영역이라는 점이 문제일까 싶다.

<img width="1433" alt="image" src="https://user-images.githubusercontent.com/28949162/204507614-f9bf5145-9c56-4e89-8f6e-77bbc1cff6fb.png">

인스턴스가 모두 작동중임에도 불구하고 node-exporter가 다운 되있다.

<img width="840" alt="image" src="https://user-images.githubusercontent.com/28949162/204508168-7d8254ad-7447-47f5-b8e6-31300028ef60.png">

pod status == Ready 상태이지만, 1. 그라파나 대시보드에서 확인할 수 없고, 2. 프로메테우스 서버에서 노드 정보가 조회 불가능하다. 마스터 node-exporter를 제외한 worker 노드들 전부 node-exporter가 정상 작동하지 않는다.

```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  11s   default-scheduler  0/4 nodes are available: 1 node(s) didn't have free ports for the requested pod ports, 3 node(s) didn't match Pod's node affinity/selector.
  Warning  FailedScheduling  10s   default-scheduler  0/4 nodes are available: 1 node(s) didn't have free ports for the requested pod ports, 3 node(s) didn't match Pod's node affinity/selector.
  Normal   Scheduled         8s    default-scheduler  Successfully assigned default/prometheus-prometheus-node-exporter-544xt to ip-10-0-3-139.ap-northeast-2.compute.internal
```

Node exporter 를 제외한 나머지 컴포넌트는 제대로 작동한다 어떤게 문제일까?

curl localhost:9100/metrics 를 각 노드에서 하면 메트릭을 게시하는지는 알 수 있다. -> 각 노드에서 가능

https://ooeunz.tistory.com/139 여기에 다르면

1. 프로메테우스 서버는 익스포터가 열어둔 http endpoint 에 접속하여 exporter 가 수집한 metric을 수집하고 프로메테우스 서버에 저장한다.
2. 프로메테우스 서버가 HTTP endpoint에 접근하여 모니터링 대상의 메트릭을 수집해오도록 scrape config에 metric scrape job 을 등록할 수 있다. 이때 등록된 job 은 target url 에 연결 된 instance 들에게서 주기적으로 metric을 수집해 온다.

이를 생각해 봤을 떄, 첫 번째로 의심가는 원인은,

1. 프로메테우스 서버가 익스포터가 열어둔 http endpoint에 접속이 불가능하기 때문.

![image](https://user-images.githubusercontent.com/28949162/204684922-32ca2775-99fa-428c-9bad-5913081b40cf.png)

kubernetes-service-endpoint(job) 가 노드 익스포터에 접근하지 못하는 것일 수 있다.

kubernetes-service-endpoint 를 describe 하려고 해도 실행중인 잡을 볼 수 없다. 잡은 실행되고 역할을 끝내면 종료한다.


![image](https://user-images.githubusercontent.com/28949162/204696143-a121b424-0abb-4f88-ac40-82c9975deabc.png)


![image](https://user-images.githubusercontent.com/28949162/204699142-9c1f8820-ea6c-4965-9393-7ed7e9eab00e.png)

위 사진과 같이 다른 master node에서 다른 worker node의 메트릭이 접근 불가능하다.

이를 해결하기 위, 프로메테우스 서버가 endpoint에 접근하는 프로세스가 어떻게 되는지 알아보자.

프로메테우스는 SD를 통해 target을 가져온다. 이때, target에 대한 정보는 configMap 에 있다.

`k get configmap prometheus-server -o yaml > config_server.yaml` # configmap 확인

아래는 configMap 중 job_name: kubernetes-service-endpoints 에 대한 부분만 발췌했다.

```yaml
     job_name: kubernetes-service-endpoints
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape
      - action: drop
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: (.+?)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_service_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
    - honor_labels: true
```

봐도 무슨뜻인지 전혀 모르겠다! 

밑을 보면 엔드포인트 설정은 알맞게 되어있음을 알 수 있다.
```
 ⚡ root@ip-10-0-3-139  ~/prometheus  k describe service/prometheus-prometheus-node-exporter
Name:              prometheus-prometheus-node-exporter
Namespace:         default
Labels:            app.kubernetes.io/component=metrics
                   app.kubernetes.io/instance=prometheus
                   app.kubernetes.io/managed-by=Helm
                   app.kubernetes.io/name=prometheus-node-exporter
                   app.kubernetes.io/part-of=prometheus-node-exporter
                   app.kubernetes.io/version=1.3.1
                   helm.sh/chart=prometheus-node-exporter-4.5.2
Annotations:       meta.helm.sh/release-name: prometheus
                   meta.helm.sh/release-namespace: default
                   prometheus.io/scrape: true
Selector:          app.kubernetes.io/instance=prometheus,app.kubernetes.io/name=prometheus-node-exporter
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.97.224.120
IPs:               10.97.224.120
Port:              metrics  9100/TCP
TargetPort:        9100/TCP
Endpoints:         10.0.3.139:9100,10.0.3.205:9100,10.0.4.192:9100 + 1 more...
Session Affinity:  None

```



https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config 를 보며 의미를 파악해보자.

![image](https://user-images.githubusercontent.com/28949162/204711794-f25d1fc7-3593-4578-8713-8f722457445b.png)

https?

configmap에서 schem: https -> scheme: http 로 변경 후 재배포

![image](https://user-images.githubusercontent.com/28949162/204717839-c2b3e687-8f40-41af-b1dd-11421ce3c7b4.png)

kubernetes-node 와 kubernetes-node-cAdvisor 까지 덩달아 죽었다! 😊😊😊

원상복구 후 재배포 하자.

![image](https://user-images.githubusercontent.com/28949162/204718365-994d549d-778d-4653-9197-1f45908e5ab7.png)

원상복구하니 쟤들은 살았다. 이번 시도는 실패


### check all component logs

`k logs kube-controller-manager-ip-10-0-3-139.ap-northeast-2.compute.internal -n kube-system`

```shell
I1130 02:55:05.854543       1 event.go:291] "Event occurred" object="default/prometheus-server" kind="Service" apiVersion="v1" type="Normal" reason="EnsuringLoadBalancer" message="Ensuring load balancer"
W1130 02:55:05.948809       1 endpointslice_controller.go:305] Error syncing endpoint slices for service "default/prometheus-server", retrying. Error: EndpointSlice informer cache is out of date
```
```
W1130 02:55:07.544453       1 aws.go:3239] Error authorizing security group ingress "InvalidPermission.Duplicate: the specified rule \"peer: 10.0.2.0/24, TCP, from port: 31027, to port: 31027, ALLOW\" already exists\n\tstatus code: 400, request id: 0197821f-7e34-4ae9-8629-d479d328766e"
W1130 02:55:07.544757       1 aws_loadbalancer.go:901] Error add traffic permission to security group: "error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.2.0/24, TCP, from port: 31027, to port: 31027, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 0197821f-7e34-4ae9-8629-d479d328766e\""
W1130 02:55:07.544962       1 aws.go:4039] Error opening ingress rules for the load balancer to the instances: "error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.2.0/24, TCP, from port: 31027, to port: 31027, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 0197821f-7e34-4ae9-8629-d479d328766e\""
E1130 02:55:07.545123       1 controller.go:310] error processing service default/prometheus-server (will retry): failed to ensure load balancer: error authorizing security group ingress: "InvalidPermission.Duplicate: the specified rule \"peer: 10.0.2.0/24, TCP, from port: 31027, to port: 31027, ALLOW\" already exists\n\tstatus code: 400, request id: 0197821f-7e34-4ae9-8629-d479d328766e"
I1130 02:55:07.545660       1 event.go:291] "Event occurred" object="default/prometheus-server" kind="Service" apiVersion="v1" type="Warning" reason="SyncLoadBalancerFailed" message="Error syncing load balancer: failed to ensure load balancer: error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.2.0/24, TCP, from port: 31027, to port: 31027, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 0197821f-7e34-4ae9-8629-d479d328766e\""
I1130 02:55:07.545679       1 event.go:291] "Event occurred" object="default/prometheus-alertmanager" kind="Service" apiVersion="v1" type="Normal" reason="EnsuringLoadBalancer" message="Ensuring load balancer"
I1130 02:55:07.751128       1 aws_loadbalancer.go:181] Creating load balancer for default/prometheus-alertmanager with name: a8600f466aecf42c0877e61b4f8c90b0
I1130 02:55:08.306416       1 aws_loadbalancer.go:574] Creating load balancer target group for default/prometheus-alertmanager with name: k8s-default-promethe-32499709c8
I1130 02:55:08.641235       1 aws_loadbalancer.go:546] Creating load balancer listener for default/prometheus-alertmanager
W1130 02:55:09.191197       1 aws.go:3239] Error authorizing security group ingress "InvalidPermission.Duplicate: the specified rule \"peer: 10.0.0.0/24, TCP, from port: 32594, to port: 32594, ALLOW\" already exists\n\tstatus code: 400, request id: 05f8fc07-00e6-4d4c-8cdd-ef5ae3e5acd7"
W1130 02:55:09.191240       1 aws_loadbalancer.go:901] Error add traffic permission to security group: "error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.0.0/24, TCP, from port: 32594, to port: 32594, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 05f8fc07-00e6-4d4c-8cdd-ef5ae3e5acd7\""
W1130 02:55:09.191261       1 aws.go:4039] Error opening ingress rules for the load balancer to the instances: "error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.0.0/24, TCP, from port: 32594, to port: 32594, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 05f8fc07-00e6-4d4c-8cdd-ef5ae3e5acd7\""
E1130 02:55:09.191293       1 controller.go:310] error processing service default/prometheus-alertmanager (will retry): failed to ensure load balancer: error authorizing security group ingress: "InvalidPermission.Duplicate: the specified rule \"peer: 10.0.0.0/24, TCP, from port: 32594, to port: 32594, ALLOW\" already exists\n\tstatus code: 400, request id: 05f8fc07-00e6-4d4c-8cdd-ef5ae3e5acd7"
I1130 02:55:09.191582       1 event.go:291] "Event occurred" object="default/prometheus-alertmanager" kind="Service" apiVersion="v1" type="Warning" reason="SyncLoadBalancerFailed" message="Error syncing load balancer: failed to ensure load balancer: error authorizing security group ingress: \"InvalidPermission.Duplicate: the specified rule \\\"peer: 10.0.0.0/24, TCP, from port: 32594, to port: 32594, ALLOW\\\" already exists\\n\\tstatus code: 400, request id: 05f8fc07-00e6-4d4c-8cdd-ef5ae3e5acd7\""
I1130 02:55:12.553172       1 event.go:291] "Event occurred" object="default/prometheus-server" kind="Service" apiVersion="v1" type="Normal" reason="EnsuringLoadBalancer" message="Ensuring load balancer"
I1130 02:55:13.156513       1 event.go:291] "Event occurred" object="default/prometheus-server" kind="Service" apiVersion="v1" type="Normal" reason="EnsuredLoadBalancer" message="Ensured load balancer"
I1130 02:55:14.193757       1 event.go:291] "Event occurred" object="default/prometheus-alertmanager" kind="Service" apiVersion="v1" type="Normal" reason="EnsuringLoadBalancer" message="Ensuring load balancer"
I1130 02:55:14.558405       1 event.go:291] "Event occurred" object="default/prometheus-alertmanager" kind="Service" apiVersion="v1" type="Normal" reason="EnsuredLoadBalancer" message="Ensured load balancer"

```






### kubernetes api server 확인

`k logs  pod/kube-apiserver-ip-10-0-3-139.ap-northeast-2.compute.internal -n kube-system`

E1130 02:53:05.831201       1 watch.go:251] unable to encode watch object *v1.WatchEvent: write tcp 10.0.3.139:6443->10.0.3.205:12990: write: broken pipe (&streaming.encoder{writer:(*framer.lengthDelimitedFrameWriter)(0xc00da0c4e0), encoder:(*versioning.codec)(0xc010cc7cc0), buf:(*bytes.Buffer)(0xc00c9b58c0)})

10.0.3.139:6443 은 master node 의 kube-api server 이다.
```
 ⚡ root@ip-10-0-3-139  ~/prometheus  k describe pod/kube-apiserver-ip-10-0-3-139.ap-northeast-2.compute.internal -n kube-system
Name:                 kube-apiserver-ip-10-0-3-139.ap-northeast-2.compute.internal
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Node:                 ip-10-0-3-139.ap-northeast-2.compute.internal/10.0.3.139
Start Time:           Tue, 29 Nov 2022 04:43:56 +0000
Labels:               component=kube-apiserver
                      tier=control-plane
Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.0.3.139:6443
```


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


