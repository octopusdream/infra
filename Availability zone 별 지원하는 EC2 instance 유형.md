### ❗ 이슈 발생

- ec2(instance) 유형 t2.micro로 설정한 후 ec2(instance)를 Availability Zone(a,b,c)에 생성하려고 하였으나 아래과 같은 이슈가 발생하였다.

```
Your requested instance type (t2.micro) not supported in your requested Availability Zone (ap-northeast-2b). 
Please retry your request by not specifying an Availability Zone or choosing ap-northeast-2a, ap-northeast-2c.
```

- 요약하자면 해당 Availability Zone(가용 영역)에는 해당하는 ec2(instance) 유형을 지원하지 않는다.

### 🤔 Availability Zone 별 지원하는 ec2 유형
- 그렇다면 어떤 Availability Zone(가용 영역)에서 어떤 ec2(instance) 유형을 지원하는지 확인을 해보자

![image](https://user-images.githubusercontent.com/88362207/200502832-0ad809a9-8704-475c-b042-70aba8baf69d.png)
- ec2 콘솔 접속

![](https://velog.velcdn.com/images/yange/post/dd1e2cce-8044-4afa-a488-5dd1403fab2e/image.png)
- 인스턴스 유형 속성에서 가용 영역 선택

![](https://velog.velcdn.com/images/yange/post/1983fb31-310c-4b18-b2d9-69536bd8153d/image.png)
- 총 6가지 종류의 가용 영역을 확인 할 수 있다.

### 서울 region 6가지 가용 영역
① 가용 영역: ap-northeast-2a, ap-northeast-2c
- t2, c4 계열 등

② 가용 영역: ap-northeast-2a, ap-northeast-2b, ap-northeast-2c, ap-northeast-2d
- t3, c5 계열 등

③ 가용 영역: ap-northeast-2a, ap-northeast-2b, ap-northeast-2c
- t3, c5 계열 등

④ 가용 영역: ap-northeast-2a, ap-northeast-2d
- mac1.metal 

⑤ 가용 영역: ap-northeast-2d
- t3, c5 계열 등

⑥ 가용 영역: ap-northeast-2c
- t2, t3, c4, c5 계열 등

### 💡 결론
- t2.micro는 대표적으로 Availability Zone(a,c)에서만 지원한다.
- t3.micro 등 여러 ec2(instance) 유형은 4개 가용영역 모두에서 지원하는 것을 확인할 수 있다.
