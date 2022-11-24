## Why Slack?

젠킨스에서 빌드를 할 시 지금 빌드를 하면 바로 성공과 실패를 확인할 수 있지만, Cron Job 의 경우는 직접 젠킨스 주소로 들어가서 확인해야하는 번거로움이 있다. 만약에 중요한 Job이 제 시간에 빌드가 안되었을 경우, 이를 바로 확인하지 못하면 서비스에 문제가 생길 가능성도 존재한다. 편리성과 빌드 실패 시 위험성을 줄이기 위해 실시간으로 빌드 확인 여부를 확인할 수 있도록 Jenkins와 Slack을 연동하려 한다.

## Slack Setting

### **Add channels to be notified**

![image](https://user-images.githubusercontent.com/93571332/203712650-bdde9770-df70-41e2-8d5d-e0577ca84d19.png)

### **Add Jenkins App to Slack**

![image](https://user-images.githubusercontent.com/93571332/203712684-2823e8f5-1e25-4445-8b85-17e985a2d9c0.png)

### **Set up channels to receive notifications from Jenkins**

![image](https://user-images.githubusercontent.com/93571332/203712720-86ee2cf2-1ad0-4195-ba88-150af45a3cab.png)

### CopyTeam Subdomain & Integration Token Credential ID

![image](https://user-images.githubusercontent.com/93571332/203712751-331f18e7-4a8e-49f0-a155-75f4eebcea88.png)

### Check **Configurations**

![image](https://user-images.githubusercontent.com/93571332/203712780-12e8b28a-1f7a-4df9-8510-141c9866a0f8.png)

## Jenkins Setting

### Download Slack Notification Plug In

![image](https://user-images.githubusercontent.com/93571332/203712804-8dcadd6e-ae4d-4516-91af-c8b58e76f0bb.png)

### **Setting Slack In System Settings**

시스템 설정으로 가서 Slack 구성으로 가 설정을 한다.

Workspace에 팀 하위 도메인을 입력, Default channel에는 초반에 만든 채널명 (jenkins) 를 작성한다.

![image](https://user-images.githubusercontent.com/93571332/203712864-20256cb9-62b5-4a68-9bb0-b9a8b7442ee4.png)

Credential에 Add 를 입력하여 통합 토큰 자격 증명 ID, 적당한 ID 이름을 입력한다.

팀 하위 도메인, 통합 토큰 자격 증명 ID의 경우 위에 ‘CopyTeam Subdomain & Integration Token Credential ID’ 단계에서 확인해 볼 수 있다.

![image](https://user-images.githubusercontent.com/93571332/203712893-7dfd834c-dae5-458c-a493-502ae970f2da.png)

Test Connection 을 입력하여 Success 를 확인하고 저장을 한다.

밑에 사진은 Success 가 뜰 시 Slack 채널에서 받는 메세지이다.

![image](https://user-images.githubusercontent.com/93571332/203712920-c631e72e-d78a-4d13-aa3b-1c993a48168e.png)

### Change Jenkinsfile

참고 ) [https://mia15.tistory.com/entry/17-Jenkins-Slack-연동](https://mia15.tistory.com/entry/17-Jenkins-Slack-%EC%97%B0%EB%8F%99)

```bash
pipeline {
    agent any
    environment {
        NEXUS_CREDS = credentials('nexus')
        JENKINS_IP = '3.37.129.159'
        **SLACK_CHANNEL = '#jenkins'** # 슬랙 채널 설정
    }
    stages {
        # 파이프라인 시작 시 알림 발송
        **stage('Start') {
            steps {
                slackSend (channel: SLACK_CHANNEL, color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
            }
        }**
        stage('Clone Repo') {
            steps {
                checkout scm
                sh 'ls *'
            }
        }
        stage('Build Image') {
            steps {
                sh '/etc/init.d/docker start'
                sh 'docker build -t ${JENKINS_IP}:5001/flask_test:$BUILD_NUMBER .'
            }
        }
        stage('Docker Login') {
            steps {
                sh 'echo $NEXUS_CREDS_PSW | docker login ${JENKINS_IP}:5001 -u $NEXUS_CREDS_USR --password-stdin'                
            }
        }
        stage('Docker Push') {
            steps {
                sh 'docker push ${JENKINS_IP}:5001/flask_test:$BUILD_NUMBER'
            }
        }
    }
    post {
        always {
            sh 'docker logout ${Jenkins_IP}:5001'
        }
        # 파이프라인 종료 시 결과 알림 발송
        **success {
            slackSend (channel: SLACK_CHANNEL, color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend (channel: SLACK_CHANNEL, color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }**
    }
}
```

## **Send Notification**

![image](https://user-images.githubusercontent.com/93571332/203712961-9691932c-6a69-4003-925f-5ffe469c596e.png)

![image](https://user-images.githubusercontent.com/93571332/203712993-cd5e2cd5-7a66-453f-bebf-bef6d4f7280b.png)
