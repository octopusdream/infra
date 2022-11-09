![image](https://user-images.githubusercontent.com/93571332/200238132-22db955c-edf2-47a2-9470-639394041869.png)

위에는, 프로젝트 구현 들어가기 전 간단하게 설계해본 CI/CD 아키텍처이다. 당연히, 추후에 수정이 있을 수 있다. 

Github, Jenkins, Dockerhub, Helm 을 사용하여 CI 를 파트를 구현하고, Jenkins, ArgoCD, Kubernetes를 통해 CD 파트를 구현할 예정이다. 이러한 과정을 통한 파이프라인 실행 결과는 사용자가 바로 확인할 수 있도록 파이프라인 실행 결과를 Slack 으로 전달한다. 

추가적으로, 쿠버네티스의 경우 실제로 사용해보면 pod 가 잘 배포가 안된다든지, 이미지가 문제가 생기는지 등 다양한 오류를 만날 수 있다. 이러한 경우 보다 더 쉽게 트러블 슈팅을 할 수 있게 하기 위해 로깅 시스템으로 EFK(Fluentd + Elasticsearch + Kibana)를 쿠버네티스 클러스터 상에 구현할 예정이다.
 

## 1차 수정 아키텍처
![image](https://user-images.githubusercontent.com/93571332/200776206-fa5fd69d-3a53-45c0-a337-21670c6464ae.png)
