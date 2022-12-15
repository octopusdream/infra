# Goal
>
Flask application을 monitoring한다.

# Summary

>
prometheus official python client library 를 기반으로 만든 exporter 인 flask prometheus metrics를 사용한다. flask_prometheus_metrics는 메트릭 익스포터로써 플라스크 앱으로 만든 웹 애플리케이션의 중요한 메트릭을 제공한다.
>
prometheus service discovery  를 수정하여 application endpoints를 dynamic 하게 디스커버리 할 수 있어야 한다.

# 애플리케이션 모니터링을 위한 과정

## 애플리케이션 메트릭을 어떻게 수집하나? - 클라이언트 라이브러리

메트릭은 누군가 메트릭을 만들기 위한 계측 코드를 추가해야한다. 이 부분을 관여하는 것이 클라이언트 라이브러리다. **코드로 메트릭을 정의하고, 제어하려는 코드에 인라인으로 원하는 계측 기능을 추가할 수 있다. 이를 직접 계측이라고 한다.**

클라이언트 라이브러리는 모든 주요 언어와 런타임에 사용할 수 있다. Go, Python 등 주요 언어는 클라이언트 라이브러리를 제공한다. Node.js, Erlang 같은 다양한 서드파티 클라이언트도 있다.

클라이언트 라이브러리는 스레드 안정성, bookkepping, HTTP 요청에 대한 응답으로 프로메테우스 텍스트 게시 형식 생성 같은 모든 핵심 세부사항을 처리한다. 메트릭 기반 모니터링은 개별 이벤트를 추적하지 않기 때문에 메모리를 사용한다고 해서 이벤트가 더 늘어나지는 않는다. 오히려 메모리는 사용하는 메트릭 개수와 관련된다.

## 익스포터 - Using Prometheus_Flask_exporter based on Official Prometheus Client Library

**Exporter**

대부분 시스템 커널 같은 소프트웨어에는 메트릭에 접근할 수 있는 인터페이스가 있다.

익스포터는 가져오고 싶은 메트릭을 애플리케이션 바로 옆에 배치하는 소프트웨어다. 익스포터는 프로메테우스로부터 요청을 받아서, 애플리케이션에서 요청된 데이터를 수집하고, 데이터를 올바른 형식으로 변환한 다음, 마지막으로 프로메테우스에 대한 응답으로 데이터를 반환한다. 익스포터는 애플리케이션의 메트릭 인터페이스를 프로메테우스의 게시 형식으로 변환하는 일대일 방식의 작은 프록시라고 생각해도 좋다.

flask_prometheus_metrics 는 HTTP request metrics을 프로메테우스로 익스포트 해준다. 직접 계측 코드를 추가하지 않아도 해당라이브러리에서 제공하는 HTTP request metrics을 수집할 수 있어 간편하다. 

## Export

metric을 export 할 포트설정을 해준다.

4. Scrape Dynamically 

## Prometheus scrape config

타겟은 static_config 를 통해 정적으로 설정될 수 있다.

혹은, 서비스 디스커버리 메커니즘을 사용하여  dynamically discovered 할 수 있다. 

dynamic한 pod endpoint를 가져오기 위해 필요한 지식을 살펴본다.

### kubernetes_sd_config

Kubernetes SD Configuration을 사용하면 Kubernetes의 REST API에서 스크랩 대상을 검색하고 항상 클러스터 상태와 동기화된 상태를 유지할 수 있다.

다음 role type 중 하나를 구성하여 대상을 검색할 수 있다.

#### node

node role은 클러스터 노드당 하나의 대상을 검색하며, 주소는 기본적으로 kubelet의 HTTP 포트로 설정된다. 대상 주소는 기본적으로 NodeInternalIP, NodeExternalIP, NodeLegacyHost, NodeHostName 의 주소 유형 순서에 따라 Kubernetes 노드 개체의 첫 번째 기존 주소로 설정된다.

#### service

service role은 각 서비스에 대한 각 서비스 포트의 대상을 검색한다. 일반적으로 블랙박스 모니터링에 유용하다. 주소는 서비스 및 해당 서비스 포트의 Kubernetes DNS 이름으로 설정된다.



#### pod

pod role은 모든 포드를 검색하고 해당 컨테이너를 대상으로 노출한다. 컨테이너의 선언된 각 포트에 대해 single target이 생성된다. 컨테이너에 지정된 포트가 없는 경우 relabeling을 통해 수동으로 포트를 추가하기 위한 port-free target이 컨테이너당 생성된다.

#### endpoints

endpoints role은 서비스 리스트에서 타겟을 발견한다. 각 엔드포인트 주소는 포트당 발견된다. 엔드포인트가 파드 뒤에 있을 때, 엔드포인트 포트에 바인딩되지 않은 포드의 모든 추가 컨테이너 포트도 대상으로 검색된다.



### relabel_config

kubernetes_sd_config 뿐만 아니라 relabel_config도 알아야한다.

relabeling은 대상이 스크래핑되기 전에 대상의 레이블 세트를 동적으로 다시 작성할 수 있는 강력한 도구이다. 스크랩 설정당 여러 레이블링 단계를 구성할 수 있다. 설정 파일에 나타나는 순서대로 각 대상의 레이블 세트에 적용된다.

처음에는 설정된 대상별 레이블을 제외하고 대상의 작업 레이블은 각 스크랩 구성의 job_name 값으로 설정됩니다. __address__ 레이블은 대상의 host:port 주소로 설정된다. 레이블을 다시 지정한 후 인스턴스 레이블은 레이블을 다시 지정하는 동안 설정되지 않은 경우 기본적으로 __address__ 값으로 설정된다. __scheme_ 및 __metrics_path_ 레이블은 각각 대상의 체계 및 메트릭 경로로 설정된다. __param_name 레이블은 name 이라는 첫 번째 전달된 URL 매개 변수의 값으로 설정됩니다.

__scrape_interval__ 및 __scrape_timeout__ 레이블은 대상의 간격 및 시간 초과로 설정된다.

레이블을 다시 지정하는 단계에서 __meta_가 앞에 붙은 추가 레이블을 사용할 수 있다. 이들은 대상을 제공한 서비스 검색 메커니즘에 의해 설정되며 메커니즘마다 다르다

#### source labels
source label은 기존 라벨에서 값을 선택한다. Their content is concatenated using the configured separator and matched against the configured regular expression
for the replace, keep, and drop actions. 

연결된 소스 라벨 값 사이에 separator가 있다.

바꾸기 작업에서 결과 값이 기록되는 레이블입니다.
교체 작업의 경우 필수입니다. 정규식 캡처 그룹을 사용할 수 있습니다.

#### target labels

replace action에서 결과 값이 기록되는 label이다. replace actions일 경우 필수이다. 정규식 캡처 그룹을 사용할 수 있다.



Reference
- https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- https://pypi.org/project/prometheus-flask-exporter/
- https://blog.viktoradam.net/2020/05/11/prometheus-flask-exporter/
- https://github.com/prometheus/client_python: 오피셜 파이썬 클라이언트 라이브러리
- https://blog.sebastian-daschner.com/entries/prometheus-kubernetes-discovery
- https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/



