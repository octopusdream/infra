
### NAT Gateway

VPC Endpoint 를 사용하지 않으면  private subnet 에 위치한 인스턴스가 AWS 서비스인 S3에 연결할 때 NAT Gateway 를 사용하여 internet gateway 를 통해 S3 에 접속하게 된다. 

NAT Gateway 를 사용하는 경우에는 서버 외부로 트래픽이 전달되어 상대적으로 요금이 많이 발생한다.

![image](https://user-images.githubusercontent.com/72699541/201563413-a0a3d2ef-9428-4737-b335-06c935d3470a.png)

---

### VPC Endpoint

VPC Endpoint 를 사용해 private subnet 에 위치한 인스턴스가 AWS 서비스인 S3에 연결할 때에 NAT Gateway 를 사용하는 대신 S3와의 통신을 담당하는 접점인 Endpoint 을 만들어서 연결하도록 한다.

AWS 내에 위치한 S3와 같은 서버리스 서비스를 사용하게 되는 경우에는 endpoint 를 사용하여 상대적으로 발생하는 요금을 절약할 수 있다.

endpoint
![image](https://user-images.githubusercontent.com/72699541/201563905-77c95b5d-730d-4aa6-8db6-a47b086ff7b0.png)


---

### terraform S3용 gateway VPC endpoint 를 생성

```bash
# s3 endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id = "${aws_vpc.kakao_vpc.id}"
  service_name = "com.amazonaws.ap-northeast-1.s3"
}
```

### terraform private subnet 의 route table 에 연결

```bash
# private subnet - route table association
resource "aws_vpc_endpoint_route_table_association" "route_table_association_a" {
  route_table_id = "${aws_route_table.kakao_pria_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_b" {
  route_table_id = "${aws_route_table.kakao_prib_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association_c" {
  route_table_id = "${aws_route_table.kakao_pric_rt.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}
```

- 확인
![image](https://user-images.githubusercontent.com/72699541/201561969-2560a990-90b2-4e6c-a06e-644891d2dbd8.png)
