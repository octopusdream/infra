### NAT Gateway

VPC 보안을 위해 EC2나 ECS, RDS와 같은 인스턴스를 private subnet에 위치하도록 하면 이에 대한 인터넷 트래픽을 위해 NAT Gateway가 필요하다.

- 기본적인 subnet 분리에 따른 구성
![image](https://user-images.githubusercontent.com/72699541/200501343-e2f2a1ba-8b30-4c9c-bca9-78050a19262e.png)

- Internet Gateway

Internet Gateway 는 VPC 인스턴스가 인터넷에 연결되기 위해 반드시 필요하다. private subnet 과 public subnet 의 차이를 결정짓는 요소이기도 하다. private subnet 과 달리 public subnet 은 모든 트래픽(0.0.0.0/0)에 대해 Internet Gateway 로 트래픽이 라우팅된다.


> Internet Gateway 는 그 자체로도 NAT이며, public IP를 갖고있다.
> 


- NAT Gateway

NAT Gateway는 NAT(네트워크 주소 변환) 서비스이다. private subnet 의 인스턴스가 VPC 외부의     서비스에 연결할 수 있지만 외부 서비스에서 이러한 인스턴스와의 연결을 시작할 수 없도록 NAT Gateway 를 사용할 수 있다. 보통, public subnet 에 위치하여, private subnet 에 인터넷 트래픽을 전달하는 용도로 사용된다. 

> 고가용성을 위해 2개 이상의 AZ에서 리소스가 운용한다면 NAT Gateway를 AZ 당 1개씩 만들어주어야 한다.
> 

-----

### 비용 문제

VPC 에 NAT Gateway 를 생성하는 경우, 프로비저닝되고 사용 가능한 NAT에 대해 NAT Gateway 시간당 요금이 부과된다. 데이터 처리 요금은 트래픽 소스나 대상과 관계없이 NAT Gateway 를 통해 처리된 각 기가바이트에 적용된다.

- [NAT Gatway](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-nat-gateway.html) 를 통해 전송되는 데이터 요금, `NAT-Gateway-Bytes`

[논리적으로 격리된 가상 네트워크 - Amazon VPC 요금 - Amazon Web Services](https://aws.amazon.com/ko/vpc/pricing/)

서버 인스턴스가 AWS 상에서 구동되는 경우, 서버 외부로 트래픽이 전달되기 보다는 AWS 내에 위치한 데이터베이스나, S3와 같은 서버리스 서비스를 사용하게 되는 경우가 많은데, 이 경우에는 굳이 NAT 게이트웨이 대신에 VPC 엔드포인트라는 기능을 사용하여, 상대적으로 발생하는 요금을 절약할 수 있다.

---

### **VPC Endpoint**

VPC Endpoint 는 ****private subnet 에 위치한 인스턴스가 AWS 서비스에 연결할 때에 NAT Gateway 를 사용하는 대신 사용하려는 AWS 서비스와의 통신을 담당하는 접점을 만들어서 연결하도록 하는 VPC 구성 요소이다.

> 하나의 VPC Endpoint 에는 하나의 서비스만 지정할 수 있다.
> 

- EC2 가 S3로의 접근이 필요한 경우, NAT Gateway 를 붙여 연결하게 하는 대신, S3 VPC Endpoint 를 하나 만들어 통신이 가능하도록 할 수 있다.
![image](https://user-images.githubusercontent.com/72699541/200501483-e68fb115-3ed2-4c48-92c4-b8547bb13b03.png)

---

### VPC Endpoint 서비스 유형

EndPoint 서비스에 필요한 VPC EndPoint 유형을 생성해야 한다.

- `Interface`
    
    트래픽을 분산하기 위해 Network Load Balancer를 사용하는 엔드포인트 서비스로 트래픽을 보내는 *인터페이스 엔드포인트 를 생성합니다.* 엔드포인트 서비스로 향하는 트래픽은 DNS를 사용하여 확인됩니다.
    
    AWS 서비스의 진입점 역할을 하는 프라이빗 IP가 있는 탄력적 네트워크 인터페이스(ENI). 해당 프라이빗 IP를 사용하여 EC2/ECS에서 AWS 서비스에 연결합니다. 인터페이스 엔드포인트 비용은 처음 1PB에 대해 시간당 $0.01 및 GB당 $0.01입니다. 
    
    [AWS PrivateLink 요금 - Amazon Web Services](https://aws.amazon.com/ko/privatelink/pricing/)
    
- `GatewayLoadBalancer`
    
    *게이트웨이 로드 밸런서 엔드포인트* 를 생성 하여 프라이빗 IP 주소를 사용하여 가상 어플라이언스 집합에 트래픽을 보냅니다. 라우팅 테이블을 사용하여 VPC에서 게이트웨이 로드 밸런서 엔드포인트로 트래픽을 라우팅합니다. 게이트웨이 로드 밸런서는 트래픽을 가상 어플라이언스로 분산하고 수요에 따라 확장할 수 있습니다.
    
- `Gateway`
    
    프라이빗 IP 주소를 사용하여 **Amazon S3 또는 DynamoDB**로 트래픽을 전송 하는 *게이트웨이 엔드포인트 를 생성합니다.* 라우팅 테이블을 사용하여 VPC에서 게이트웨이 엔드포인트로 트래픽을 라우팅합니다. 게이트웨이 엔드포인트는 AWS PrivateLink를 활성화하지 않습니다.
    

---

### 결론

<aside>
💡 AWS에서 서비스 운영 시 Private subnet 에 위치한 인스턴스가 VPC 외부의 AWS 서비스를 이용하고자 할 때 NAT Gateway 가 아닌 VPC Endpoint 를 사용하면 비용을 줄일 수 있다.

</aside>
