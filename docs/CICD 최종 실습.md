## Trigger Setting

### **Trigger ManifestUpdate**

이후에 만들 updatemanifest job 에게 전달할 파라미터를 설정한다.

BUILD_NUMBER 값을 가지는 DOCKERTAG를 전달할 예정이다.

App Repo 의 Jenkinsfile에 아래와 같은 코드를 추가해준다.

```bash
[jenkinsfile] - flask_test
...
    stage('Trigger ManifestUpdate') {
        steps {	
            build job: 'updatemanifest', parameters: [string(name: 'DOCKERTAG', value: env.BUILD_NUMBER)]
        }
    }
...
```

### **Trigger Backup**

App Repo 의 Jenkinsfile에 jenkins의 주요 설정을 백업할 job을 불러올 수 있도록 아래와 같은 코드를 추가해준다.

```bash
[jenkinsfile] - flask_test
...
    stage('Trigger Backup') {
        steps {	
            build job: 'jenkins-backup'
        }
    }
...
```

## Create a New Job (CD)

k8s_gitops_test 레포지토리에 다음과 같은 Jenkinsfile 을 추가한다.

앞에서 먼저 실행되는 Job에서 받은DOCKERTAG 파라미터 값을 토대로 k8s_gitops_test 레포지토리에 deployment.yaml 파일에서 docker image 가 변경되도록 git 설정을 해준다.

```bash
node {
    def app
    env.JENKINS_IP = '43.201.66.100'
    stage('Clone repository') {    
        checkout scm
    }
    stage('Update GIT') {
        script {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                withCredentials([usernamePassword(credentialsId: 'github', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh "git config user.email yusine51@gmail.com"
                    sh "git config user.name YUYUYUJINN"
                    sh "cat deployment.yaml"
                    sh "sed -i 's+${JENKINS_IP}:5001/flask_test.*+${JENKINS_IP}:5001/flask_test:${DOCKERTAG}+g' deployment.yaml"
                    sh "cat deployment.yaml"
                    sh "git add ."
                    sh "git commit -m 'Done by Jenkins Job changemanifest: ${env.BUILD_NUMBER}'"
                    sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/octopusdream/k8s_gitops_test.git HEAD:master"
                }
            }
        }
    }
}
```

Jenkinsfile 작성을 완료하면, 위에 jenkinsfile 을 실행시킬 job을 하나 생성한다. (updatemanifest)

매개변수 설정

![image](https://user-images.githubusercontent.com/93571332/204202477-79e50250-cddb-42e2-b99a-0a1e17a2f171.png)

Pipeline 설정

![image](https://user-images.githubusercontent.com/93571332/204202500-ae34b907-2901-4d4d-a36e-8dfd7c4955d1.png)

### 참고

CI/CD 테스트 실습 영상 주소 : [https://youtu.be/DKAo8rdZc5U](https://youtu.be/DKAo8rdZc5U)
