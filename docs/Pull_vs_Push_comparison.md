해당 포스팅은 [AlibabaCloud Blog: Pull or Push: How to Select Monitoring Systems?](https://www.alibabacloud.com/blog/pull-or-push-how-to-select-monitoring-systems_599007) 를 기반으로 작성했습니다.

## 🔥 Goal
>
모니터링 시스템의 메트릭 수집 방식인 Pull 과 Push에 대해 원리적으로 비교해본다. Pull 과 Push 방식에 대해 비교해보며 모니터링 시스템의 작동방식에 대한 이해를 도모한다. 결과적으로 어떤 모니터링 시스템을 선택할지 생각해본다.


## Metric 수집 방식: Pull vs Push
![](https://velog.velcdn.com/images/hyunshoon/post/3a57f3a3-5053-4aca-a45f-8d96194bcce5/image.png)

pull 기반 모니터링 시스템은 능동적으로 지표를 획득하는 모니터링 시스템으로, 모니터링이 필요한 오브젝트에 원격으로 접근할 수 있어야 한다. 

push 기반 모니터링 시스템은 모니터링이 필요한 오브젝트가 적극적으로 지표를 푸시한다.

두 가지 방법에는 여러 측면에서 차이점이 크다. 모니터링 시스템의 구축 및 선택을 위해서는 두 가지 방법의 장단점을 미리 이해하고 적절한 구현 방식을 선택해야 한다.


아래 그림은 Pull vs Push Monitoring 을 다양한 측면에서 비교한 표이다. 자세한 내용은 밑에서 다룬다.
![](https://velog.velcdn.com/images/hyunshoon/post/5828d326-dc59-4dad-b99a-7fd37733d976/image.png)


## Principle and Architecture Comparison

![](https://velog.velcdn.com/images/hyunshoon/post/9bc3b72a-f971-40a3-824e-6573632c7490/image.png)

좌측: Pull 우측: Push

### Pull

![](https://velog.velcdn.com/images/hyunshoon/post/c998b113-0512-4653-84f3-2de088f8d426/image.png)

위 그림에서 보듯이 Pull 모델의 데이터 수집 방식의 핵심은, 프로메테우스와 같은 모니터링 백엔드와 함께 일반적으로 배포되는 **Pull Module** 이다. 핵심 구성요소는 다음과 같다.

Host service dsicovery(일반적으로 회사의 CMDB system을 따름), Application service discovery(Consul 등), PaaS service discovery(K8s 등)을 포함하는 **Service Discovery System**이다.

Pull module은 이런 service discovery system에 연결할 수 있는 기능이 있어야 한다. 서비스 디스커버리 파트 이외에도, Pull module은 remote end에서 데이터를 pull하기 위한 공통 프로토콜을 사용한다. 일반적으로 pull interval, timeout interval, metric filtering, rename 및 간단한 프로세스 기능 설정을 제공한다.

Application-end SDK 는 풀을 위한 고정 포트를 제공한다.

다양한 미들웨어 및 기타 시스템이 Pull protocol과 호환되지 않으므로 Exporter에 해당하는 Agent를 개발하여 이러한 시스템의 메트릭을 풀링하고 표준 Pull interface를 제공해야한다.

### Push

**Push Model Architecture**
![](https://velog.velcdn.com/images/hyunshoon/post/fd92146c-dea3-48d4-8777-4addf2933ec9/image.png)

푸시 모델은 단순하며, 다음과 같이 설명할 수 있다.

Push Agent는 모니터링되는 다양한 오브젝트의 메트릭 데이터를 가져와 서버에 푸시할 수 있도록 지원한다. 모니터링 시스템과 결합된 방식으로 배포될 수 있고, 분리되어 배포될 수도 있다.

ConfigCenter (optional)는 모니터링 대상, 수집 간격, 메트릭 필터링, 메트릭 처리 및 remote targets와 같은 중앙 집중식 동적 구성 기능을 제공할 수 있다.

Application-end SDK는 모니터링 백엔드나 로컬 에이전트로의 데이터 전송을 지원한다. (일반적으로 로컬 에이전트는 백엔드 인터페이스로 구현.)

요약하면, Pull model의 배포방식은 미들웨어 및 기타 시스템을 모니터링 하기에는 너무 복잡하며 유지 보수 비용도 높다. 반면에 Push model은 비교적 쉽고 편리하다. Metrics port를 제공하는것과 사전예방적인 push를 배포하는 것의 비용은 거의 같다.

## Pull's Distributed Soulution

![](https://velog.velcdn.com/images/hyunshoon/post/0cac2cf5-189d-4e3e-82aa-8581d032b10b/image.png)

확장성 측면에서, Push 데이터 수집은 기본적으로 분산된다. 모니터링 백엔드 기능이 지원하는 경우 제한없이 수평적 확장이 가능하다. 대조적으로 Pull 확장 방식은 더 까다롭고 다음과 같은 조건이 필요하다.

Pull module은 모니터링 백엔드와 분리되며, Pull은 에이전트 별로 배포된다.

Pull Agent는 분산 협업을 해야하고, 가장 간단한 방법이 샤딩이다.

예를들어, Service Discovery system 으로 부터 모니터링되는 시스템 목록을 가져오고 이러한 시스템에서 해시 모듈 작업을 수행하고 Pull through 샤딩을 담당하는 에이전트를 확인 할 수 있다. Configuration center(optional)을 추가해서 각 Pull agent를 관리 할 수 있다. 이미 알겠지만, 이 분산 방식에는 여전히 몇 가지 문제가 있다.

단일 지점 병목 현상이 여전히 존재하며, 모든 agent가 service discovery module을 요청해야 한다.

agent가 확장되면, 모니터링 대상이 변경되어, 데이터 중복 또는 누락이 발생할 수 있다.

## Monitoring Capabilities Comparison

### Monitoring Target Survivability

생존가능성은 모니터링에 필요한 첫 번째이자 가장 기본적인 작업이다. Pull mode에서는 모니터링 타겟의 생존가능성을 확인하는게 비교적 간단하다. Pull 중심부에서, 타겟 지표를 요청할 수 있는지 확인할 수 있다. 오류가 발생하면, 네트워크 시간 초과 및 피어 연결 거부와 같은 간단한 오류에 대한 알림을 받는다.

Push mode는 문제가 있다. 애플리케이션이 보고하지 않으면 애플리케이션 고장, 네트워크 문제 또는 애플리케이션이 다른 노드로 마이그레이션 했을수도 있다. Pull module은 Service Discovery(SD)와 실시간으로 필터 상호작용을 수행할 수 있고 Push 모드는 이를 수행할 수 없으므로 서버가 SD 와 상호 작용한 후에만 구체적인 실패 원인을 알 수 있다.

### Data Completeness Calculation

데이터 완전성 개념은 대규모 모니터링 시스템에서 더 중요하다. 예를 들어, 1,000개의 복사본을 가진 트랜잭션 애플리케이션의 QPS를 모니터링할 때, 우리는 이 지표와 1,000개의 데이터를 결합해야 한다. 데이터 완전성이 없을 때, QPS가 2% 감소된 알람을 트리거하도록 구성되었다고 가정해보자. 이 경우, 데이터가 20개가 넘는 복사본 데이터가 네트워크 변동으로 인해 몇 초 지연되면 오경보가 발생하게 된다. 따라서 알람을 구성하면서 데이터의 완전성을 고려할 필요가 있다.

데이터 완전성 계산도 SD 모듈에 따라 달라진다. Pull 방법은 데이터를 차례로 풀링하여 한 번 풀링하면 데이터가 완성된다. 일부 풀링에 실패하더라도 불완전한 데이터의 백분율을 알 수 있다.

반면에, Push 모드는 각 Agent와 Application은 push를 사전 예방적으로 수행한다. 각 클라이언트의 푸시 간격과 네트워크 지연 시간이 다르다. historical situation에 따라 서버가 데이터 완전성을 계산해야하므로 막대한 비용이 발생한다.

### Short Lifecycle/Serverless Application Monitoring

실제 시나리오에는 짧은 생명 주기/서버리스 애플리케이션이 많이 있다. 특히 비용 친화적인 경우에 우리는 많은 수의 작업, 탄력적 인스턴스, 서버리스 애플리케이션을 사용할 것이다. 예를들어, rendering task가 도착한 후 탄력적 인스턴스가 시작된다. 완성되면, 즉각적으로 destroy되고 release 될 것이다. 머신러닝 트레이닝, 이벤트 중심 서버리스 워크플로우, 정기적으로 실행되는 작업(예: 리소스 정리, 용량 검사 및 보안 검사)에서도 상황은 동일하다. 이러한 애플리케이션은 일반적으로 짧은 수명 주기(초 또는 밀리초 이내)를 가집니다. Pull의 일반적인 모델은 모니터링하기 어렵다. 일반적으로, 애플리케이션이 모니터링 데이터를 사전 예방적으로 푸시하도록 하려면 Push를 써야한다.

이러한 짧은 수명 주기 애플리케이션을 관리하기 위해 순수한 Pull 시스템은 애플리케이션의 사전 예방적 Push를 수락하는 중간 레이어(예: 프로메테우스 Push Gateway)를 제공한 다음 모니터링 시스템에 pull 포트를 제공한다. 그러나 이는 추가 중간 계층의 관리 및 O&M 비용으로 이어진다. 이 모드는 Pull simulating Push를 통해 구현되므로 보고 대기 시간이 길어지며, 즉시 사라지는 이러한 메트릭은 제때 정리해야 한다.

### Flexibility and Coupling

유연성 측면에서는 Pull mode가 유리하다. Pull module에서 원하는 지표를 구성하고 지표에 대한 간단한 계산과 2차 처리를 할 수 있다. 하지만, 이 장점이 압도적이지는 않다. Push SDK/Agent 또한 이런 매개변수를 설정할 수 있다. Configuration Center의 도움으로 구성 관리가 간단하다.

Pull model과 백엔드 사이의 결합도는 낮다. 백엔드가 인식할 수 있는 인터페이스만 제공하면 된다. 어떤 백엔드가 연결되어 있고 백엔드가 어떤 지표가 필요한지 알 필요가 없다. 분업이 분명하다. 애플리케이션 개발자는 애플리케이션의 지표만 노출하면 되고, SRE(Site Reliability Engineer)는 이러한 지표를 얻을 수 있다. 

Push model의 결합도가 더 높다. 애플리케이션에서 백엔드 주소와 인증 정보를 구성해야 한다. 그러나, local push agent에 의존하여 애플리케이션은 오직 로컬 주소만 알면되고 이는 큰 비용이 들지 않는다.

## Resource and O&M Cost

### Resource Cost

전체 비용 측면에서, 두 접근 방식 사이에는 약간의 차이가 있지만 비용 분포를 고려한다면:

Pull 모드의 비용은 주로 monitoring system-end 에 집중되며, application-end 의 비용은 낮다.

Push 모드의 비용은 주로 Push Agent-end 에 집중되며 monitoring system-end 에서의 비용은 pull에 비해 훨씬 낮다.

### O&M Cost

O&M의 경우 Pull 모드의 비용이 더 높다. Pull 모드의 O&M을 담당하는 구성 요소는 다양한 exporters, SD, Pull Agent, Monitoring Backend가 있다. Push 모드는 Push Agent, Monitoring Backend 및 Configuration Center에 대한 O&M만 수행하면 된다.

여기서 한 가지 주의할 점은 Pull 모드에서는 서버가 클라이언트에 대한 요청을 능동적으로 시작하므로, 애플리케이션 측의 교차 클러스터 연결 및 네트워크 보호 ACL을 네트워크에서 고려해야 한다는 것이다. Push에 비해 네트워크 연결은 간단하며 각 노드가 액세스할 수 있는 도메인 이름/VIP만 서버에 제공하면 된다.

## Pull or Push Selection

현재 오픈소스 솔루션 중 pull 패턴의 대표는 프로메테우스 패밀리 솔루션이다. (패밀리라 칭하는 것은 프로메테우스만의 확장성은 제한적이기 때문이다. 프로메테우스는 Thanos, VicoriaMetrics, Cortex와 같은 기술 커뮤니티에 많은 분산 솔루션을 보유하고 있다.) TICK(Telegraf, InmusionDB, Chronograf, Capacitor) 솔루션은 Push 패턴을 나타낸다.

두 솔루션은 모두 장단점이 있다. 클라우드 네이티브를 배경으로 프로메테우스는 CNCF와 쿠버네티스의 인기와 함께 번창하기 시작했다. 따라서 많은 오픈소스 소프트웨어는 이미 Prometheus 모드에서 Pull port를 제공하기 시작했다. 하지만, 많은 시스템은 설계 초기에 Pull port를 제공하는데 어려움을 겪었다. 이러한 시스템을 모니터링 하려면 Push Agent 방법이 더 적합하다. 

애플리케이션에서 Pull 또는 Push를 사용해야하는지에 대한 결론은 없다. 구체적인 선택은 여전히 회사 내의 실제 시나리오에 기초해야 한다. 예를 들어, 회사의 네트워크 클러스터가 매우 복잡할 경우 Push를 쉽게 사용할 수 있다. 수명 주기가 짧은 많은 애플리케이션은 Push를 사용해야 한다. 모바일 애플리케이션은 Push만 사용할 수 있다. 시스템 자체는 SD를 위해 Consul를 사용한다. 이는 Pull port를 export한 후 구현하기 쉽다.

따라서 사내 모니터링 시스템의 경우 Pull 과 Push 의 기능을 모두 갖춘 것이 최적의 솔루션이다.

Host, process 및 middleware 모니터링에서는 Push Agent를 사용한다.
Kubernets 및 기타 직접 exposed 된 pull ports는 Pull mode를 사용한다.
Applications는 시나리오에 따라 풀 또는 푸시를 선택한다.


Reference
- https://www.alibabacloud.com/blog/pull-or-push-how-to-select-monitoring-systems_599007
