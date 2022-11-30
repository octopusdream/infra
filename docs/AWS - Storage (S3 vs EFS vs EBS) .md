본 프로젝트에서 우리는 현재 S3, EFS Storage 서비스를 사용중이다.

그렇기에, 본 글에서 각 Storage 서비스들에 대한 설명을 한 후, 우리가 왜 이 서비스를 이용했는지에 대해 설명해보려한다.

다음과 같은 순서로 설명하겠다.
```
0. 간단한 Amazon S3 대 EFS 대 EBS 비교
1. S3는 무엇인가?
2. EBS는 무엇인가?
3. EFS는 무엇인가?
4. 왜 이 storage 서비스를 선택하였는가?
```
### Amazon S3 대 EFS 대 EBS 비교

![image](https://user-images.githubusercontent.com/88362207/202939003-45f76c65-7f1e-45b3-be38-ade383e7480e.png)

|EBS|S3|EFS|
|:---:|:---:|:---:|
|block 스토리지|Object 스토리지|shared File 스토리지|
|EC2에 마운트 가능|EC2에 마운트 불가능|EC2에 마운트 가능|
|빈번한 Read/Write에 추천| Write oncce Read many times에 추천|빈번한 Read/Write에 추천|
|서비스를 붙일 때 AZ에 제한 있음|서비스를 붙일 때 AZ에 제한 없음|서비스를 붙일 때 AZ에 제한 없음|
|평균|싸다|비싸다|
|높은 호환성 및 Sync|낮은 호환성 및 Sync|높은 호환성 및 Sync|
|파일 수정 가능|파일 수정 불가능(덮어써야한다)|파일 수정 가능|

---
### S3(Amazon Simple Storage Service) - 데이터 저장 및 백업에 적합
![image](https://user-images.githubusercontent.com/88362207/202969110-68792166-6c68-426a-980d-d555597b1ba0.png)

```
확장가능하고, 내구성이 뛰어나 기용성이 좋고, 공개적으로 액세스가능한 데이터스토리지
```

S3는 계층 구조가 없는 평평한 환경(계층 구조 x)에 객체로 데이터를 저장한다. 저장소의 각 object(파일)에는 해당 바이트 시퀀스(0B ~ 5TB까지)가 있는 헤더가 포함되어 있다.

> Object Storage 
>
> 만약 우리 컴퓨터에 1GB 파일을 Object Storage에 올려 같은 작업을 했다고 가정한다면, 변경된 파일은 새로운 Object로 인식하며 기존의 파일은 지우고 새로운 파일로 모두 대체한다. 데이터를 조금이라도 수정할 경우 모든 데이터를 변경하다 보니 Read/Write가 빈번한 환경이라면 작업이 오래 걸린다는 단점이 있다.
> 
> 하지만 단순한 구조로 읽기 속도가 빠르다는 점과 높은 확장성 및 비용이 저렴한 장점이 있다.

```
1024KB = 1MB
1024MB = 1GB
1024GB = 1TB
```

이 저장소 유형의 개체는 고유 식별자(key)와 연결되므로, 어디에서나 웹 요청을 통해 액세스할 수 있다. 예를 들어 자체 데이터 센터의 승인된 노드 혹은 외부 사용자는 버킷의 모든 객체에 액세스 할 수있다.
(S3는 구조화 되지 않은 데이터를 위한 스토리지 서비스이다. 예를 들면 S3는 널리 사용되는 데이터 백업 대상이다.)

빈번한 업데이트가 없는 파일을 올릴때 용이하게 쓰인다.

정적인 웹사이트 콘텐츠 호스팅도 허용한다. (S3 버켓이나 CDN AWS Cloud Front를 통해 액세스 가능)

---
### EBS(Elastic Block Storage) - 가상 머신용 드라이브
![image](https://user-images.githubusercontent.com/88362207/202969090-fe7a1c8c-9e47-4be6-a7ba-9f5c5d121978.png)

```
가상 머신을 위한 드라이브
```

AWS EC2(Elastic Compute Cloud)에서 사용하도록 설계된 사용하기 쉬운 고성능 블록 스토리지 서비스이다.
(S3와 같은 독립형 스토리지 서비스가 아니므로 EC2와 결합하여 사용해야 한다.)

> Block Storage
> 
> 블록 스토리지는 만약 우리 컴퓨터에 1GB 파일이 저장되어 있다면, 그 파일은 컴퓨터 하드디스크의 몇개의 블록에 할당 되어 있을 것이다. 
> (각 파티셔닝에 따라 다르겠지만, 만약 한 블록을 1024KB라고 가정한다.)
> 
> 그렇다면 1GB 크기의 파일은 1024개의 블록을 차지하고 있는 것이다. 
> 만약 우리가 1GB 크기의 파일을 수정하고 저장했다고 한다면, 그 결과로 1024의 블럭 모두가 업데이트 되는 것이 아니라 1개의 블록만이 변경될 것이다.
> 
> 이처럼 블록 스토리지는 블록 단위의 작업을 지원하기 때문에 변경된 데이터만 최신화해주면 되는 것이다. 
> 이런 이유로 블록 스토리지는 낮은 I/O 레이턴시(반응 시간)를 자랑하며, Read/Write 작업이 빠르다는 장점이 있다. 
> 만약 자주 파일이 업데이트되고, Read/Write 작업이 빈번하다면 블록 스토리지 사용을 권장한다.

```
1024KB = 1MB
1024MB = 1GB
1024GB = 1TB
```

컴퓨터나 노트북에 연결된 하드 드라이브와 유사하지만 가상화된 환경에있다. 물리적 시스템의 로컬 디스크 드라이브처럼 Amazon EC2 인스턴스에 연결된 전용 볼륨에 데이터를 저장하도록 설계되어 있다. (데이터를 동일한 크기의 블록으로 저장하고 기존 파일 시스템과 유사한 계층을 통해 데이터를 구성)

EBS는 볼륨을 다른 EC2에 연결하거나 대기 모드로 유지하는 것만 허용한다. 볼륨이 EBS에 구성되면 쉽게 확장할 수 없기 때문에, 더 많은 저장 공간이 필요한 경우 더  큰 크기의 볼륨을 구입하여 구성하고 마운트해야 한다.

---
### EFS
![image](https://user-images.githubusercontent.com/88362207/202969123-b14d743c-e552-405a-9859-14ba86741c97.png)

```
가상머신을 위한 확장 가능한 스토리지
```
> shared File Storage
> 
> 파일 수준 또는 파일 기반 스토리지라고도 한다.
> 서류철에 서류를 정리하듯, 데이터가 폴더 안에 단일 정보로 저장된다. 해당 데이터에 액세스해야 하는 경우, 컴퓨터는 그 데이터를 찾기 위해 경로를 알아야한다.(경로가 길고 찾기 어려울 수 있다.) 
> 
> 파일에 저장된 데이터는 제한된 양의 메타데이터(해당 파일 자체가 보관된 정확한 위치를 알려주는 데이터)를 사용해 구성 및 검색 된다. 간단한 조직의 스키마이지만, 데이터 양이 늘어나면 파일과 폴더를 추적하기 위해 파일 시스템에 대한 자원 요구가 증가하기 때문에 성능이 떨어질 수 있다. 이러한 구조적 문제는 단순하게 파일 시스템에서 사용할 수 있는 저장 공간을 늘리는 것으로 해결할 수 없다.

EBS는 VM용 시스템 드라이브를 구성하는데 적합하고 S3는 스토리지에 적합하지만, 확장 가능한 스토리지와 상대적으로 빠른 출력이 필요한 워크로드가 높은 애플리케이션을 실행하려면 EFS를 사용하면 된다.

EFS를 다양한 AWS 서비스에 탑재하고 다양한 가상 머신에서 액세스할 수 있다. EFS는 서버, 공유 볼륨, 빅 데이터 분석 등 생각할 수 있는 모든 확장 가능한 워크로드 실행에 유용하다.

EFS의 분산설계는 병목현상을 방지하고 기존 파일 서버에 내재된 제약에 구애를 받지 않는다. EFS의 데이터는 여러 가용영역(AZ)에 분산되어 있어 높은 수준의 내구성 및 가용성을 제공한다.(EBS는 여러 가용영역에 분산 할 수 없다.)
각기 다양한 서버에서 하나의 파일 시스템으로 데이터를 공유하고 싶을때 사용한다.

EFS는 자동으로 확장이 가능하다. 즉, 워크로드가 갑자기 증가해도 실행 중인 애플리케이션에 아무런 문제가 없고 그에 따라 스토리지가 확장된다. 워크로드가 감소하면 스토리지 양이 자동적으로 축소하므로 사용하지 않은 스토리지에 대해 비용을 지불하지 않아도 된다. 

---


### 왜 이 storage 서비스를 선택하였는가?
그렇다면 우리는 어떤 경우로 S3와 EFS를 왜 선택하여서 사용했는가?

S3는 현재 동시에 같은 파일을 수정하지 못하도록 막기 위해 DynamoDB를 사용하여 Locking의 기능을 하면서, terraform의 상태를 저장하기 위해 Backup을 위한 bucket을 생성하였다.
또한, 누가 접근해서 작업했는지 알 수 있도록 기록하는 log용 bucket도 생성하였다. 

> 본 프로젝트에서는 EBS와 EFS는 Read/Write가 빈번할 경우에 적합한 storage인데, terraform의 log 파일과 Backup을 위한 .ftstate 파일은 빈번한 업데이트가 없는 파일로 적은 비용으로 S3를 용이하게 사용할 수 있다.
> log 파일과 Backup 파일은 함부로 수정하면 안되므로, 파일 수정이 불가능한 S3가 더 좋다.  
> S3는 데이터를 가져오는 속도가 EBS - EFS - S3 순으로 가장 느리기 때문에 상대적으로 비용이 저렴하기 때문에 S3가 log 파일이나 .tfstate 파일을 빠르게 저장할 필요가 없기 때문에 적합하다. 
> S3와 같은 원격 저장소를 사용함으로써 state 파일의 유실을 방지할 수 있다.


EFS는 각 가용영역마다 private subnet에 속해있는 EC2(worker node)에서 데이터를 저장하기 위해 확장 사용 가능한 파일 스토리지 서비스를 사용하고 있다.

> 본 프로젝트에서는 사용하는 가용영역이 3개이기 때문에, AZ에 제한이 있는 S3를 사용하는 것보다는 EFS를 사용하는 것이 호환성 및 Sync가 더 높을것으로 생각했기 때문이다. 
> 
> 자세한 설명은 https://github.com/octopusdream/infra/blob/yang/docs/multiple_availability_zones_cluster.md 를 참고하길 바란다.