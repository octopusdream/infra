## 배포 전략

### Recreate

![recreate](https://user-images.githubusercontent.com/59433441/201871310-31fc0383-d4ef-4504-8b65-d0fa259e70ce.png)

- 기존에 실행 중이던 파드들을 모두 제거한 후 새로운 파드를 실행
- 예시
        
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name : myapp-deployment-blue
    spec:
        replicas: 3
        strategy: 
        	type: Recreate
        template: 
        ...
    ```
        

### Rolling Update

![rolling](https://user-images.githubusercontent.com/59433441/201871321-d04978cb-4657-46b0-8c01-a41ab9e22282.png)

- `Deployment`의 기본 배포 방법
- 배포된 전체 파드를 한꺼번에 교체하는 것이 아닌 일정 개수씩 교체하면서 배포하는 방식
- 파드를 하나씩 죽이고 새로 띄우는 순차적인 교체 방법
- 업데이트 프로세스 동안 두 가지 버전의 컨테이너가 동시에 실행되어서 버전 호환성 문제 발생 가능
- `maxUnavailable`, `maxSurge` 파라미터 이용
    - `maxUnavailable`에 지정된 값만큼 이전 버전의 파드들을 바로 제거하고 새로운 파드를 생성
        - 절대 숫자 또는 파드 비율 지정
    - `maxSurge`는 의도한 파드 수에 대해 생성할 수 있는 최대 파드의 수를 지정
        - 절대 숫자 또는 파드 비율 지정
- 예시
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: myapp-deployment
    spec:
      selector:
        matchLabels:
          app: myapp
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
      template: 
      ...
    ```
    
    - `maxSurge`, `maxUnavailable` 파라미터를 지정하여 배포 수행

### Blue/Green

![bluegreen](https://user-images.githubusercontent.com/59433441/201871330-5247b275-ef0d-447a-ad27-f33fbb8e5b02.png)

- 기존에 실행된 파드 개수만큼 신규 파드를 모두 실행
- 신규 파드가 정상적으로 실행되면 한꺼번에 트래픽을 옮기는 방식
- 신버전과 구버전이 같이 존재하는 시간 없이 순간적인 교체 가능
- 롤링 업데이트보다 필요한 리소스 양이 많음
- 예시
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name : myapp-deployment-blue
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: myapp
          color: blue
      template:
        metadata:
          labels:
            app: myapp
            color: blue
        spec:
          containers:
            - name: myapp
              image: gcr.io/project/application:0.1
              ports:
                - containerPort: 8080
    ```
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: myapp-service
    spec:
      ports:
        - port: 80
          targetPort: 8080
      selector:
        app: myapp
        color: blue
    ```
    
    - `blue` deployment가 먼저 배포되었다고 가정
    - deployment는 service에 연결되어 있음
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name : myapp-deployment-green
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: myapp
          color: green
      template:
        metadata:
          labels:
            app: myapp
            color: green
        spec:
          containers:
            - name: myapp
              image: gcr.io/project/application:0.2
              ports:
                - containerPort: 8080
    ```
    
    ```yaml
    # blue-green.yaml
    spec:
      selector:
        color: green
    ```
    
    ```bash
    $ kubectl patch service myapp-service -p "$(cat blue-green.yaml)"
    ```
    
    - 버전이 업데이트 되면 새로운 버전의 deployment를 배포
    - service의 selector를 `green`으로 변경

### Canary

![canary](https://user-images.githubusercontent.com/59433441/201871346-bd3b09ba-8f7e-44a4-bb62-be892c25bce9.png)

- 기존 버전을 유지한 채로 일부 버전만 신규 파드로 교체
- 구버전과 신버전이 같이 존재
- 버그 확인, 사용자 반응 확인할 때 유용
- 예시
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: myapp-deployment
      labels:
        app: myapp
        version: stable
    spec:
      replicas: 4
      selector:
        matchLabels:
          app: myapp
          version: stable
      template:
        metadata:
          labels:
            app: myapp
            version: stable
        spec:
          containers:
          - name: myapp
            image: gcr.io/project/application:0.1
            ports:
            - containerPort: 8080
    ```
    
    - `stable` 버전의 deployment이 배포되어 있는 상태
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: myapp-deployment-canary
      labels:
        app: myapp
        version: canary
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: myapp
          version: canary
      template:
        metadata:
          labels:
            app: myapp
            version: canary
        spec:
          containers:
          - name: myapp
            image: gcr.io/project/application:0.2
            ports:
            - containerPort: 8080
    ```
    
    - `canary` 버전의 deployment 작성
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: myapp
      name: myapp-service
    spec:
      type: NodePort
      selector:
        app: myapp
      ports:
      - nodePort: 30010
        port: 8080
        protocol: TCP
        targetPort: 8080
    ```
    
    - 서비스를 위와 같이 작성하면 replicas에 지정한 개수 비율로 번갈아 가며 요청이 실행
        - 서비스의 selector와 `stable` 버전, `canary` 버전의 label이 같기 때문에

---
참고
- https://www.weave.works/blog/kubernetes-deployment-strategies