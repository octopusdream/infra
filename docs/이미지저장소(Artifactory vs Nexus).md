## 이미지저장소

호스트에서 생성한 이미지를 쿠버네티스에서 사용하려면 모든 노드에서 공통으로 접근하는 레지스트리(저장소)가 필요하다.

이번 프로젝트에서는 직접 만든 이미지를 외부에 공개하지 않을 예정이기에 사설 이미지 저장소를 사용할 것이다.

도커 허브에서 제공하는 사설 저장소가 있지만, 사설 저장소는 무료 사용자에게는 1개 밖에 허용되지 않으며 비공개 저장소를 사용하려면 유료 구독을 해야한다.

제약 없이 사용할 수 있는 저장소가 필요하다면 레지스트리를 직접 구축하는 방법이 있다.

이 경우, 인터넷을 연결할 필요가 없으므로 보안이 중요한 내부 전산망에서도 구현이 가능하다.

이번 프로젝트에서는 Artifactory 또는 Nexus 둘 중 하나를 사용할 예정이다.

## Artifactory vs Nexus

다음은, Devops 자동화, CI/CD 기능과 관련해서 Artifactory 와 Nexus 를 비교한 표이다.

![image](https://user-images.githubusercontent.com/93571332/200774943-0ec30c89-c8ef-4300-9b28-b8fff15321b2.png)

Artifactory 의 프로모션 기능으로 JFrog CLI, REST 또는 Jenkins Plugin for Artifactory를 통해 접근이 가능하다.

## Artifactory

JFrog Artifactory는 바이너리 저장소 관리 도구이다. 도커 이미지 통합 및 관리, Opkg 패키지 개발, 저장소 이중화를 지원한다. 

또한, NuGet 패키지 호스트와 프록시, Npm 패키지 및 RubyGems 호스트를 지원한다.

즉, JFrog Artifactory는범용적인 결과물 저장소이며 도커, npm, NuGet 등에서 산출될 결과물을 지원한다.

### 참고

1: [https://jfrog.com/blog/artifactory-vs-nexus-integration-matrix/](https://jfrog.com/blog/artifactory-vs-nexus-integration-matrix/)

2: [https://www.sonatype.com/compare/sonatype-nexus-versus-jfrog-artifactory](https://www.sonatype.com/compare/sonatype-nexus-versus-jfrog-artifactory)
