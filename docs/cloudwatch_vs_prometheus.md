## Goal
>
환경: AWS EC2 인스턴스를 사용하여 Multi AZ  k8s Cluster 구성
>
>
이때, **AWS 모니터링 서비스인 CloudWatch와 가장 인기 있는 오픈소스 모니터링 툴인 Prometheus를 비교** 후 선택한다.
>
AZ 간 통신에 ISP를 필수적으로 거쳐야 한다. 각 AZ에서  Metric, Log 와 같은 데이터를 하나의 모니터링 서버에 초 단위, 분 단위로 전송을 해야하기 때문에 ISP를 거치는 데이터 전송 비용이 현재 핵심 우려요소이다. 이를 중심으로 비교해본다.
![](https://velog.velcdn.com/images/hyunshoon/post/db2619ef-c0e3-4d7e-94ac-dac6cb206b15/image.png)

## CloudWatch
![](https://velog.velcdn.com/images/hyunshoon/post/157c7fd0-606a-4119-99ad-913854538fa1/image.png)
>
CloudWatch는 AWS 서비스로서 인프라시스템과 애플리케이션을 모니터링하고 관리한다. 리소스는 AWS 나 온프레미스 혹은 둘 다 있을 수 있다. 애플리케이션 성능 데이터와 인프라 모니터링 정보는 동일한 대시보드에 로그 또는 메트릭으로 동시에 표시될 수 있다. CloudWatch는 메트릭 및 로그 수집에서 모니터링, 경고 및 분석에 이르기까지 모든 작업을 수행한다. CloudWatch에는 알람 및 이벤트 기능이 모두 있어 특정 조건이 충족될 경우 이를 알려준다. CloudWatch는 메트릭당 요금을 부과하며, 이 경우 대용량 메트릭을 처리하는 비용이 경쟁 모니터링 솔루션보다 훨씬 더 많이 증가할 수 있다.


## Prometheus
![](https://velog.velcdn.com/images/hyunshoon/post/649e82d3-52e9-44b4-8fd0-0c15e146124e/image.png)

[프로메테우스에 대한 설명은 여기에 정리](https://velog.io/@hyunshoon/Monitoring-Prometheus%EB%A1%9C-Kubernetes-%ED%81%B4%EB%9F%AC%EC%8A%A4%ED%84%B0-%EB%AA%A8%EB%8B%88%ED%84%B0%EB%A7%81)

# CloudWatch vs Prometheus

### CloudWatch 로 쿠버네티스 클러스터 모니터링

가장 큰 차이점은 컨테이너와 파드에 대한 모니터링 가능 여부였다.

[CloudWatch vs Prometheus](https://www.infracloud.io/blogs/prometheus-vs-cloudwatch/) 글에 따르면 2018년 까지는 CloudWatch를 사용하여 직접적으로 컨테이너와 파드에 대한 모니터링을 할 수 없었다. 하지만 현재 [AWS 문서](https://docs.aws.amazon.com/ko_kr/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) 를 참고하면 CloudWatch의 Container Insights를 사용해 모니터링 할 수 있다.
>
CloudWatch **Container Insights**를 사용해 컨테이너화된 애플리케이션 및 마이크로서비스의 지표 및 로그를 수집하고 집계하며 요약할 수 있다. Container Insights는 Amazon Elastic Container Service(Amazon ECS), Amazon Elastic Kubernetes Service(Amazon EKS), Amazon EC2의 Kubernetes 플랫폼에서 사용할 수 있다. 

## Cost!

### Prometheus

프로메테우스는 오픈소스이므로 무료이지만 데이터 저장 비용과 **전송 비용**을 고려해야한다. 우리는 Multi AZ 아키텍처를 가지므로 데이터를 송신할 때 ISP 를 거쳐야하기 때문에 데이터 전송 비용이 핵심일 것으로 예상된다. 
![](https://velog.velcdn.com/images/hyunshoon/post/de791145-c4a1-478d-a2b3-fcfe8fd118e2/image.png)
EC2 인스턴스를 사용할 때 인터넷을 사용하는 비용은 **GB 당 0.126$** 이다.


### CloudWatch


**Metrics**: Amazon EC2 세부 모니터링 요금은 사용자 지정 **지표 수**를 기준으로 책정되며 지표 전송에 대한 **API 요금** 은 없다. 

**Dashboard**: 대시보드당 월별 3$

**Log**: 데이터 수신 요금은 부과되지 않는다. CloudWatch Logs에서 송신된 데이터에 대해서는 EC2 요금 페이지의 "Amazon EC2에서 데이터가 송신되는 위치" 및 **"Amazon EC2에서 인터넷으로 데이터 송신"** 표에 나온 요금과 동일한 요금이 부과된다. 
![](https://velog.velcdn.com/images/hyunshoon/post/de791145-c4a1-478d-a2b3-fcfe8fd118e2/image.png)


CloudWatch **Container Insights**는 CloudWatch 지표를 자동으로 만드는 CloudWatch Logs로 성능 이벤트를 수집한다. 이러한 성능 이벤트는 CloudWatch Logs Insights 쿼리를 사용하여 분석되며 일부 Container Insights 자동화 대시 보드(예: 작업/팟, 서비스, 노드, 네임스페이스)로 자동 실행된다. 
![](https://velog.velcdn.com/images/hyunshoon/post/9a9aabac-9a60-471d-86de-9ab86d40cd2a/image.png)


Container Insights를 사용하여 컨테이너 및 파드를 모니터링하는데, 데이터 수집 비용이 **GB 당 0.76 USD** 다. 프로메테우스의 각 AZ에서 ISP를 거쳐 데이터를 전송하는데 발생하는 비용인 **GB 당 0.126 USD** 보다 비싸다. ISP를 거친 데이터 전송비용이 우려요소였다는 점에서 비용 때문에 CloudWatch를 쓸 필요는 없어보인다.


### 추가할 부분

>
ISP 를 거치는 데이터 전송 비용이 핵심 고려사항이었으므로 이를 중심으로 파악해보았다. 
>
비용 외적인 요소에 대해서는 비교하며 다루지 않았다. CloudWatch 와 Prometheus를 비교하는 자료 자체가 드물기 때문에 직접 CloudWatch와 Prometheus를 공부해가며 추후에 비교하여 정리하는 작업이 필요하다.



Reference

- https://aws.amazon.com/ko/cloudwatch/
- https://www.infracloud.io/blogs/prometheus-vs-cloudwatch/
- https://www.metricfire.com/blog/prometheus-vs-cloudwatch/#Pricing-comparison