## CI/CD

![image](https://user-images.githubusercontent.com/93571332/201046753-c7f8c5ce-52cc-43c7-812b-121dab33792a.png)

일반적으로 CI는 코드를 커밋하고 빌드했을 때 정상적으로 작동하는지 반복적으로 검증해 애플리케이션의 신뢰성을 높이는 작업이다.

CI 과정을 마친 애플리케이션은 신뢰할 수 있는 상태가 된다.

CD는 CI 과정에서 생성된 신뢰할 수 있는 애플리케이션을 실제 상용 환경에 자동으로 배포하는 것을 의미한다.

개발자가 소스를 커밋하고 푸시하면 CI 단계로 들어간다.

CI 단계에서는 애플리케이션이 자동 빌드되고 테스트를 거쳐 배포할 수 있는 애플리케이션인지 확인한다.

테스트를 통과하면 신뢰할 수 있는 애플리케이션으로 간주하고 CD 단계로 넘어간다.

CD단계에서는 애플리케이션을 컨테이너 이미지로 만들어서 파드, 디플로이먼트, 스테이트풀셋 등 다양한 오브젝트 조건에 맞춰 미리 설정한 파일을 통해 배포한다.

## ArgoCD란?

Argo CD 는 Kubernetes 기본 CD(지속적 배포) 도구이다.

Push 기반 배포만 가능한 외부 CD 도구와 달리 Argo CD는 업데이트된 코드를 Git 리포지토리에서 가져와 Kubernetes 리소스에 직접 배포할 수 있다.

이를 통해 개발자는 하나의 시스템에서 인프라 구성과 애플리케이션 업데이트를 모두 관리할 수 있다.

## ArgoCD 주요 기능

Kubernetes 클러스터에 애플리케이션을 수동 또는 자동으로 배포

선언적 구성의 현재 버전에 대한 애플리케이션 상태의 자동 동기화

웹 사용자 인터페이스 및 CLI

배포 문제를 시각화하고 구성 드리프트를 감지 및 수정하는 기능

다중 클러스터 관리를 가능하게 하는 RBAC(역할 기반 액세스 제어)

GitLab, GitHub, Microsoft, OAuth2, OIDC, LinkedIn, LDAP 및 SAML 2.0과 같은 공급자를 통한 SSO(Single sign-on)

GitLab, GitHub 및 BitBucket에서 작업을 트리거하는 Webhook을 지원

## ArgoCD 프로세스

1. 개발자는 애플리케이션을 변경하여 새 버전의 Kubernetes 리소스 정의를 Git 리포지토리에 푸시한다.
2. 지속적인 통합이 트리거되어 레지스트리에 새 컨테이너 이미지가 저장된다.
3. 개발자는 수동 또는 자동으로 생성되는 Kubernetes 매니페스트를 변경하여 pull 요청을 발행한다.
4. pull 요청이 검토되고 변경 사항이 기본 분기에 병합된다. 이것은 Argo CD에 변경 사항이 있음을 알리는 Webhook을 트리거합니다.
5. Argo CD는 저장소를 복제하고 애플리케이션 상태를 Kubernetes 클러스터의 현재 상태와 비교한다. 클러스터 구성에 필요한 변경 사항을 적용한다.
6. Kubernetes는 컨트롤러를 사용하여 원하는 구성을 달성할 때까지 클러스터 리소스에 필요한 변경 사항을 조정한다.
7. Argo CD는 진행 상황을 모니터링하고 Kubernetes 클러스터가 준비되면 애플리케이션이 동기화되어 있다고 보고한다.
8. ArgoCD는 다른 방향으로도 작동하여 Kubernetes 클러스터의 변경 사항을 모니터링하고 Git의 현재 구성과 일치하지 않으면 폐기한다.

## ArgoCD 프로세스를 가능하게 하는 이유

### **GitOps agent**

Argo CD는 Git 리포지토리에서 업데이트된 코드를 가져와 Kubernetes 리소스에 직접 배포한다.

하나의 시스템에서 인프라 구성과 애플리케이션 업데이트를 모두 관리한다.

### **Custom Resource Definitions (CRD)**

Argo CD는 Kubernetes 클러스터 내의 자체 네임스페이스에서 작동한다.

Kubernetes API를 확장하고 선언적 방식으로 원하는 애플리케이션 상태를 정의할 수 있도록 하는 자체 CRD를 제공한다.

Git repo 또는 Helm repo의 지침에 따라 Argo CD는 CRD를 사용하여 전용 네임스페이스 내에서 변경 사항을 구현한다.

### **CLI**

Argo CD는 몇 가지 간단한 명령으로 YAML 리소스 정의를 생성할 수 있는 강력한 CLI를 제공한다.

### **User Interface**

Argo CD는 동일한 작업을 수행하고 애플리케이션을 정의하고 관련 YAML 구성을 생성하도록 Argo CD에 요청할 수 있는 편리한 웹 기반 UI를 제공한다. 또한 포드 및 컨테이너 측면에서 결과 Kubernetes 구성을 시각화할 수 있다.

### **Multi-tenancy**

ArgoCD는 동일한 Kubernetes 환경에서 서로 다른 프로젝트에서 작업하는 여러 팀을 강력하게 지원한다. ArgoCD CRD는 특정 프로젝트에 속하는 source repo 를 읽기만 하도록 제한할 수 있으며 애플리케이션을 특정 클러스터 및 네임스페이스에 배포하도록 설정할 수 있다. 각 CRD 인스턴스에는 자체 RBAC(역할 기반 액세스 제어) 설정이 있을 수도 있다.

### **Leveraging existing tools**

많은 조직이 이미 YAML, Helm 차트, Kustomize 또는 기타 시스템을 기반으로 하는 선언적 구성에 투자했다. ArgoCD는 이러한 기존 투자를 대체하기보다는 활용한다. 이러한 형식을 사용하여 관련 CRD 정의를 자동으로 생성할 수 있다.

## ArgoCD  작동 방식

![image](https://user-images.githubusercontent.com/93571332/201046855-9a836e42-6fbf-44aa-8a76-61194c028917.png)

출처 : [https://argo-cd.readthedocs.io/en/stable/](https://argo-cd.readthedocs.io/en/stable/)

ArgoCD를 사용할 때 일반 YAML 또는 JSON 매니페스트를 비롯한 여러 유형의 Kubernetes 매니페스트를 사용하여 애플리케이션 구성을 지정할 수 있다. 

ArgoCD는 지정된 대상 환경에서 원하는 애플리케이션 상태를 자동으로 배포한다.

Updates는 Git 커밋에서 manifest의 tags, branches 또는 pinned specific versions으로 추적가능하다.

ArgoCD는 실행 중인 모든 애플리케이션을 지속적으로 모니터링하고 라이브 상태를 Git repo에 지정된 원하는 상태와 비교하는 역할을 하는 Kubernetes 컨트롤러이다.

OutOfSync로 원하는 상태에서 벗어나는 live state로 배포된 응용 프로그램을 식별한다.

ArgoCD는 편차를 보고하고 개발자가 live 상태를 원하는 상태와 수동 또는 자동으로 동기화할 수 있도록 시각화를 제공한다.

Argo CD는 Git repo의 원하는 상태에 대한 변경 사항을 대상 환경에 자동으로 적용하여 애플리케이션이 동기화 상태를 유지하도록 한다.

### 참고

[https://argo-cd.readthedocs.io/en/stable/](https://argo-cd.readthedocs.io/en/stable/)

[https://codefresh.io/learn/argo-cd/](https://codefresh.io/learn/argo-cd/)
