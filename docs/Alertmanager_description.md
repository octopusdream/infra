![](https://velog.velcdn.com/images/hyunshoon/post/cf7d5512-0cec-42bb-b362-eb3c7070f4f5/image.png)

# Alert란?

알림은 모니터링 구성 요소 중 하나이다. 모니터링이 무엇인가 생각해볼 때, 문제가 발생했을 때 사람에게 통보 해주는 기능이라고도 볼 수 있다. 즉, 모니터링에서 빠질 수 없는 핵심 요소이다.


# AlertManager란?

prometheus 서버와 같은 클라이언트 애플리케이션에서 보낸 경고를 처리한다. 프로테테우스는 지속적으로 계산이 수행되는 PromQL 형식으로 알림이 발생할 수 있는 조건을 정의할 수 있으며, 그 결과에 대한 시계열이 바로 알람이 된다.

프로메테우스는 이메일이나 메시지 등으로 알람을 직접 보내는 역할을 담당하지 않고, 그 역할은  AlertManager가 맡는다.

프로메테우스에서 알림이 발생하면 알림매니저로 전달되며, 알림 매니저는 여러 프로메테우스 서버로 부터 알림을 받을 수 있다. **알림 매니저는 알림을 그룹화하고 압축된 통보의 형태로 사용자에게 전달한다.**

## 아키텍쳐

![](https://velog.velcdn.com/images/hyunshoon/post/7945167e-8cf7-4e9a-8437-1965b3e3d6c9/image.png)


# Alert Rule

알림 규칙은 기록 규칙과 동일한 규칙 **그룹에 배치**하고 원하는 방식으로 조화시킬 수 있다.

예)

```
groups:
  - name: node_rules
    rules:
      - record: job:up:avg
        expr: avg without(instance)(up{job="node"})
      - alert: ManyInstancesDown
        expr: job:up:avg{job="node"} < 0.5
```

MoreThanHalfInstanceDown : 설정된 노드 익스포터의 절반 이상이 다운되면 발생. 

알림을 알림매니저로 전송하는 것 외에, 알림 규칙도 ALERTS로 불리우는 메트릭 형태로 채워진다. 알림의 모든 레이블에는 alertstate 레이블이 추가된다. 

## for

메트릭 기반 모니터링에서는 많은 경쟁조건이 발생한다. 네트워크 패킷 손실로 인해 수집 시간이 초과될 수 있고, 프로세스 스케줄링에 의해 지연될 수 있다. 따라서, 하나의 규칙 수행에 대한 결과를 기반으로 알림을 발생시키는 것은 그다지 좋지 않을 수 있다.

이런 경우 for 필드를 사용한다.

알림을 발생시키기 전, 최소한 for 필드에 지정한 시간 내에 해당 알림은 반환되어야 한다. for 조건이 만족될 때 까지의 알림 상태는 pending으로 인식된다. 

일반적으로 5m이다. 중요도에 따라 for 시간을 적절히 조절하면 좋다. **for 필드로 많은 거짓 양성 문제를 제거 할 수 있다.**

## Alert Label

알림을 분류한다. 알림의 심각성을 나타내는 severity 레이블이 있다.

예를들어, 머신 하나가 다운되는 일은 별 거 아닐 수 있지만, 절반 이상 다운 되는 것은 긴급상황일 수 있다.

## Annotations, template

어노테이션 필드는 무엇이 문제가 있는지에 대한 간단한 설명처럼 알림에 대한 추가적인 정보를 제공해준다. 어노테이션 필드 값은 Go 의 템플릿 시스템을 활용해 템플릿화한다.

# 무엇이 좋은 알람인가?

Nagios-style 모니터링에서는 높은 평균 부하, CPU 사용률 등 동작 중이지 않은 프로세스와 가은 잠재적인 문제점에 대해 알림을 보내는 것이 일반적이다. 문제의 잠재적 원인이 되지만 반드시 사람의 긴급한 개입이 필요한 문제를 나타내는 것은 아니다.

거짓 양성이 너무 많아지면 피로도가 높아지고 진짜 중요한 문제를 놓치게 될 수 있다. 

더 나은 접근법은 **증상에 대해 알림을 보내는 것이다.** 유저는 부하 평균이 높은 것 보다 자신이 보고 싶은 동영상 로딩이 오래 걸리는 것에 신경쓴다. 사용자가 경험하는 지연 시간이나 장애와 같은 메트릭에 대해 알림을 보냄으로써, 더 중요한 일에 집중할 수 있다.

예를들어 밤새 돌아가는 크론잡은 CPU 사용률을 증가시키지만 문제가 되지 않는다. 사용자와 맺은 SLA가 있는 경우 이는 알람을 위한 좋은 메트릭과 임계값을 설정하기 위한 좋은 시작점을 제시한다.

이상적인 목표는 모든 호출과 모든 알림 티켓에 지능적인 사람의 행동이 필요하다는 것이다.

알림과 시스템 관리에 대한 접근 방법에 대한 깊이 있는 설명은 Rob Ewaschuk가 쓴 [My Philosophy on Alerting](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit) 을 참고해보자.

# AlertManager 구성 요소

알림매니저는 알림이 통보로 변환되는 방법에 대해 제어 가능한 파이프라인을 사용자에게 제공한다.

## Grouping

유사한 성격의 alert를 단일 알람으로 분류한다. 많은 시스템이 한번에 다운되었을 때 수백 수천개의 알람이 동시에 발생하는 것을 막아준다. 

사용자는 어떤 서비스 인스턴스가 영향을 받았는지 정확히 확인하면서 단일 페이지만 가져오기를 원한다. 따라서 클러스터 및 alertname별로 경고를 그룹화하여 단일 압축 알림을 보내도록 Alertmanager를 구성할 수 있다.


## Inhibition

더 심각한 알람이 발생한다면 일부 다름 알림의 통보를 억제한다.


## Routing

하나의 알림매니저를 실행하려고 해도 모든 통보가 한 곳으로 전달되지는 않는다. 라우팅 트리를 사용해 이에 대한 구성을 할 수 있다.


# Configuration

알림매니저는 alertmanager.yml 로 불리는 YAML 파일을 통해 구성된다. 프로메테우스와 마찬가지로 SIGHUP을 전송하거나 HTTP POST 요청을 /-/reload 엔드포인트로 전송해 런타임시 구성 파일을 다시 로드할 수 있다.

반드시 경로와 수신자는 하나씩 있어야 한다.


## ToDoList

Alert classification
Alert rules



Referenece
- https://prometheus.io/docs/alerting/latest/alertmanager/
- 브라이언 브라질 『프로메테우스 오픈소스 모니터링 시스템』 O'REILLY, 2020
- https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit: 알림에 대한 나의 철학
- https://github.com/prometheus/alertmanager 
