AWS EC2를 이용하여 쿠버네티스 클러스터를 구축하고 CNI 플러그인으로 Calico를 사용하기 위해서는 몇 가지 설정이 필요하다.

먼저 테스트 환경은 다음과 같다.

- Kubernetes v1.21.1
- Docker v20.10.21
- Calico v3.24.5

## BGP Peering

기본적으로 Calico는 호스트 간 라우팅 정보를 공유하기 위해 BGP 프로토콜을 사용한다.

Calico를 설치하게 되면 Calico의 `BIRD` 컴포넌트에 의해 calico-node 간 `BGP Peering`이 발생하게 되는데, 이를 위해 179번 포트를 허용해줘야 한다.

만약 179번 포트가 닫혀 있다면 BGP peering에 실패하게 되고 calico-node는 Unhealty 상태가 된다.

```bash
$ kubectl get po -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-846d7f49d8-mjhnw   1/1     Running   1          3d
calico-node-7jkbx                          0/1     Running   7          3d
...
```

describe를 해보면 peering에 실패했다는 메세지를 볼 수 있다.

```bash
$ kubectl describe po calico-node-7jkbx -n kube-system
...
Events:
  Type     Reason          Age                  From     Message
  ----     ------          ----                 ----     -------
  Normal   Pulled          9m33s                kubelet  Container image "docker.io/calico/node:v3.24.5" already present on machine
  Normal   Created         9m33s                kubelet  Created container mount-bpffs
  Normal   Started         9m33s                kubelet  Started container mount-bpffs
  Warning  Unhealthy       4m20s                kubelet  Readiness probe failed: 2022-11-21 01:46:49.282 [INFO][1063] confd/health.go 180: Number of node(s) with BGP peering established = 0
calico/node is not ready: BIRD is not ready: BGP not established with 10.0.3.142,10.0.3.78
```

보안그룹에서 179번 포트를 허용해주면 BGP Peering에 성공하고 모든 calico-node는 READY 상태가 된다.

```bash
$ kubectl get po -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-846d7f49d8-mjhnw   1/1     Running   1          3d
calico-node-7jkbx                          1/1     Running   7          3d
calico-node-z9xbl                          1/1     Running   1          3d
calico-node-zcsbq                          1/1     Running   1          3d
```

### 다른 노드 간 파드 통신

테스트 위해 netshoot 컨테이너를 각 노드에서 실행하도록 하였다.

```bash
$ kubectl get po -o wide
NAME                       READY   STATUS        RESTARTS   AGE   IP                NODE      NOMINATED NODE   READINESS GATES
netshoot1                  1/1     Running       0          5s    192.168.235.176   worker1   <none>           <none>
netshoot2                  1/1     Running       0          5s    192.168.189.175   worker2   <none>           <none>
```

아무런 설정 없이 통신할 경우 통신이 되지 않는다.

```bash
$ kubectl exec -it netshoot1 -- bash
bash-5.2# ping -c 1 192.168.189.175
PING 192.168.189.175 (192.168.189.175) 56(84) bytes of data.
^C
--- 192.168.189.175 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

두 가지 방법을 이용하여 이를 해결할 수 있다.

### IP-in-IP 모드 사용

Calico를 설치하면 default mode로 `IP-in-IP` 모드를 사용한다.

IP-in-IP 모드는 IP를 또 다른 IP 안에 집어 넣는 캡슐화를 수행한 뒤 통신하는 방법을 말한다.

Calico는 IP-in-IP 모드를 사용하여 파드의 출발지, 목적지 IP를 `Inner IP header`에 넣고 `Outer IP header`에 노드의 출발지, 목적지 IP를 넣어 통신한다.

(캡슐화를 통해 패킷은 자신이 가상 네트워크가 아닌 물리 네트워크에 존재한다고 생각한다.)

하지만 기본적으로 AWS에서는 IP-in-IP 프로토콜을 허용하지 않는다.

따라서 Calico의 IP-in-IP 모드를 사용하기 위해서는 보안그룹에 사용자 지정 프로토콜을 추가해줘야 한다.

![calico-aws1](https://user-images.githubusercontent.com/59433441/202974442-2232e954-202c-4463-96fa-c1a738b48b41.png)

다시 통신해보면 정상적으로 되는 것을 확인할 수 있다.

```bash
$ kubectl exec -it netshoot1 -- bash
bash-5.2# ping -c 1 192.168.189.175
PING 192.168.189.175 (192.168.189.175) 56(84) bytes of data.
64 bytes from 192.168.189.175: icmp_seq=1 ttl=62 time=0.508 ms

--- 192.168.189.175 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
```

> AWS는 왜 IP-in-IP 모드를 기본적으로 허용하지 않을까? 
>
> AWS는 사용자가 보안 그룹에서 허용한 포트 및 프로토콜 외의 통신은 모두 차단하고 있다. 보안을 위해 최소한의 규칙을 추가해서 사용하는 것이 좋은데, 이를 위해 애초에 모든 규칙을 막아 놓은 것 같다.

### Direct 모드 사용

IP-in-IP 모드 대신 `Direct` 모드를 사용하여 이를 해결할 수도 있다.

Direct 모드는 `IP-in-IP` 모드와 달리 캡슐화를 진행하지 않고 파드에서 파드로 직접 보낸 것처럼 동작한다.

(호스트 네트워크를 라우팅 할 때 파드 IP가 그대로 노출된다.)

Direct 모드를 사용하기 위해서는 IP-in-IP 모드를 비활성화 해야 한다.

이를 위해 Calico의 ippool 설정을 변경한다.

```bash
# calicoctl이 먼저 설치되어 있어야 한다.
$ calicoctl get ippool default-ipv4-ippool -o yaml > calico-ippool.yaml 
```

```yaml
# calico-ippool.yaml
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  creationTimestamp: "2022-11-21T02:48:58Z"
  name: default-ipv4-ippool
  resourceVersion: "523311"
  uid: e060c782-2c8f-4a05-84ae-2ca39b0c0038
spec:
  blockSize: 26
  cidr: 192.168.0.0/16
  ipipMode: Never  # Direct 모드를 사용하기 위해 Always > Never 변경
  natOutgoing: true
  nodeSelector: all()
  vxlanMode: Never
```

```yaml
# apply 명령을 통해 변경된 설정을 적용한다.
$ calicoctl apply -f calico-ippool.yaml
Successfully applied 1 'IPPool' resource(s)
```

하지만 모드를 변경한다고 해서 통신이 되지 않는다.

이는 AWS의 `src/dst` IP 확인 기능 때문인데,  이 기능은 목적지의 IP가 호스트 네트워크의 IP가 아닌 경우 패킷을 차단하는 역할을 한다.

현재 호스트 네트워크와 파드 네트워크 IP가 다르므로 이를 해제해야 한다.

EC2에서 인스턴스를 클릭한 뒤 `작업 > 네트워킹 > 소스/대상 확인 변경 > 소스/대상 확인 중지`를 체크하여 비활성화 하면 된다.

![calico-aws2](https://user-images.githubusercontent.com/59433441/202974447-cb85516d-83c0-44f9-8a78-5bfb00b58058.png)

설정을 완료했다면 정상적으로 통신이 가능한 것을 확인할 수 있다.

```yaml
$ kubectl exec -it netshoot1 -- bash
bash-5.2# ping -c 1 192.168.189.175
PING 192.168.189.175 (192.168.189.175) 56(84) bytes of data.
64 bytes from 192.168.189.175: icmp_seq=1 ttl=62 time=0.508 ms

--- 192.168.189.175 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
```

위에서 언급한 것처럼 Direct 모드는 IP-in-IP 모드와 달리 캡슐화, 디캡슐화 오버헤드가 없기 때문에 성능상 이점이 있다는 장점이 있다.

참고로 Direct 모드를 사용하면 `tunl0` 인터페이스를 이용한 overlay 네트워크를 사용하지 않고 직접 통신하기 때문에 호스트의 라우팅 테이블이 변경된다.

```bash
# IP-in-IP 모드 사용하는 경우
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.3.1        0.0.0.0         UG    100    0        0 ens5
10.0.0.2        10.0.3.1        255.255.255.255 UGH   100    0        0 ens5
10.0.3.0        0.0.0.0         255.255.255.0   U     100    0        0 ens5
10.0.3.1        0.0.0.0         255.255.255.255 UH    100    0        0 ens5
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.189.64  10.0.3.78       255.255.255.192 UG    0      0        0 tunl0
192.168.189.173 10.0.3.78       255.255.255.255 UGH   0      0        0 tunl0
192.168.189.175 10.0.3.78       255.255.255.255 UGH   0      0        0 tunl0
192.168.219.64  0.0.0.0         255.255.255.192 U     0      0        0 *
192.168.219.74  0.0.0.0         255.255.255.255 UH    0      0        0 cali4d001776093
192.168.219.75  0.0.0.0         255.255.255.255 UH    0      0        0 calif639aaac1eb
192.168.219.76  0.0.0.0         255.255.255.255 UH    0      0        0 calia782baf2d95
192.168.235.128 10.0.3.142      255.255.255.192 UG    0      0        0 tunl0
```

Direct 모드를 사용하는 경우의 라우팅 테이블을 보면 tunl0 인터페이스 대신 호스트의 ens5 인터페이스로 경로가 변경된 것을 확인할 수 있다.

```bash
# Direct 모드 사용하는 경우
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.3.1        0.0.0.0         UG    100    0        0 ens5
10.0.0.2        10.0.3.1        255.255.255.255 UGH   100    0        0 ens5
10.0.3.0        0.0.0.0         255.255.255.0   U     100    0        0 ens5
10.0.3.1        0.0.0.0         255.255.255.255 UH    100    0        0 ens5
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.189.64  10.0.3.78       255.255.255.192 UG    0      0        0 ens5
192.168.189.173 10.0.3.78       255.255.255.255 UGH   0      0        0 ens5
192.168.189.175 10.0.3.78       255.255.255.255 UGH   0      0        0 ens5
192.168.219.64  0.0.0.0         255.255.255.192 U     0      0        0 *
192.168.219.74  0.0.0.0         255.255.255.255 UH    0      0        0 cali4d001776093
192.168.219.75  0.0.0.0         255.255.255.255 UH    0      0        0 calif639aaac1eb
192.168.219.76  0.0.0.0         255.255.255.255 UH    0      0        0 calia782baf2d95
192.168.235.128 10.0.3.142      255.255.255.192 UG    0      0        0 ens5
```

만약 Direct 모드를 사용하면서 다른 서브넷에 존재하는 노드의 파드와는 어떻게 통신할까?

기본적으로 다른 서브넷에 존재하는 노드의 경우 호스트 네트워크에서 노드 IP를 알 수 없으므로 게이트웨이로 라우팅 한다.

```bash
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.3.1        0.0.0.0         UG    100    0        0 ens5
10.0.0.2        10.0.3.1        255.255.255.255 UGH   100    0        0 ens5
10.0.3.0        0.0.0.0         255.255.255.0   U     100    0        0 ens5
10.0.3.1        0.0.0.0         255.255.255.255 UH    100    0        0 ens5
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
# 다른 서브넷에 존재하는 노드의 파드 경우 게이트웨이로 라우팅
192.168.189.78  10.0.3.1        255.255.255.192 UG    0      0        0 ens5
```

패킷이 게이트웨이에 도달하게 되면 게이트웨이는 패킷을 어디로 보내야할지 모르는 상황이 된다.

위에서 언급했던 것처럼 Direct 모드는 패킷에 파드 IP를 그대로 사용하는데, 게이트웨이는 해당 IP가 호스트 네트워크 IP가 아니기 때문이다.

이를 해결하기 위해 서브넷 간 통신에서만 IP-in-IP 기능을 활성화 할 수 있는 `CrossSubnet` 기능을 이용하면 된다.

`CrossSubnet` 기능을 이용하면 서브넷 내에서는 Direct 모드를 사용하고, 서브넷 간 통신에서는 IP-in-IP 모드를 사용한다.

```bash
# calico-ippool.yaml
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  creationTimestamp: "2022-11-21T02:48:58Z"
  name: default-ipv4-ippool
  resourceVersion: "523311"
  uid: e060c782-2c8f-4a05-84ae-2ca39b0c0038
spec:
  blockSize: 26
  cidr: 192.168.0.0/16
  ipipMode: CrossSubnet  # CrossSubnet 모드를 사용하기 위해 Never > CrossSubnet 변경
  natOutgoing: true
  nodeSelector: all()
  vxlanMode: Never
```

설정을 변경한 후 라우팅 테이블을 확인해 보면 해당 라우팅에 한해서 정보가 변경되었음을 확인할 수 있다.

```bash
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.3.1        0.0.0.0         UG    100    0        0 ens5
10.0.0.2        10.0.3.1        255.255.255.255 UGH   100    0        0 ens5
10.0.3.0        0.0.0.0         255.255.255.0   U     100    0        0 ens5
10.0.3.1        0.0.0.0         255.255.255.255 UH    100    0        0 ens5
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
# ens5 인터페이스가 아닌 tunl0 인터페이스로 변경
192.168.189.78  10.0.3.78       255.255.255.192 UG    0      0        0 tunl0
```