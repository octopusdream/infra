## 사전 준비 사항

Ubuntu 버전 : 20.04.5

docker 버전 : 20.10.18

## 도커를 사용하여 사설 레지스트리 Artifactory 구축

### Artifactory Docker image 다운로드

```bash
root@master:~# sudo docker pull docker.bintray.io/jfrog/artifactory-oss:latest
...
root@master:~# docker image ls
REPOSITORY                                TAG                   IMAGE ID       CREATED         SIZE
docker.bintray.io/jfrog/artifactory-oss   latest                8b51258291b7   6 days ago      1.36GB
...
```

### 디렉토리 생성

컨테이너에서 사용되는 데이터가 지속적으로 유지되도록 호스트 시스템에 데이터 디렉토리를 생성

```bash
root@master:~# mkdir -p /jfrog/artifactory
root@master:~# chown -R 1030 /jfrog/
```

### **JFrog Artifactory container 시작**

```bash
# 포트 8081, 8082 를 열음
# 8081 : Artifactory REST API 용
# 8082 : UI, 기타 모든 제품의 API 용
root@master:~# sudo docker run --name artifactory -d -p 8081:8081 -p 8082:8082 \
> -v /jfrog/artifactory:/var/opt/jfrog/artifactory \
> docker.bintray.io/jfrog/artifactory-oss:latest
```

### **Artifactory 서비스 실행**

```bash
root@master:~# vi /etc/systemd/system/artifactory.service
[Unit]
Description=Setup Systemd script for Artifactory Container
After=network.target

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker kill artifactory
ExecStartPre=-/usr/bin/docker rm artifactory
ExecStart=/usr/bin/docker run --name artifactory -p 8081:8081 -p 8082:8082 \
  -v /jfrog/artifactory:/var/opt/jfrog/artifactory \
  docker.bintray.io/jfrog/artifactory-oss:latest
ExecStop=-/usr/bin/docker kill artifactory
ExecStop=-/usr/bin/docker rm artifactory

[Install]
WantedBy=multi-user.target

root@master:~# systemctl daemon-reload
root@master:~# systemctl start artifactory
root@master:~# systemctl enable artifactory
root@master:~# systemctl status artifactory
...
     Active: active (running) since Thu 2022-11-10 11:45:02 KST; 7s ago
...
```

### 웹 상에서 접근

admin/password 로 로그인 가능

로그인 이후, get started -> 비밀번호 리셋  (Test$123로 했음)

![image](https://user-images.githubusercontent.com/93571332/201001342-6d676e54-e419-4f93-a223-6a7849ae0cb5.png)

![image](https://user-images.githubusercontent.com/93571332/201001380-906abfc0-51da-4082-8aa5-e99eb10f06c7.png)

### 참고

[https://jfrog.com/knowledge-base/how-to-install-jfrog-artifactory-with-docker-video/](https://jfrog.com/knowledge-base/how-to-install-jfrog-artifactory-with-docker-video/)

[https://jfrog.com/blog/how-to-set-up-a-private-remote-and-virtual-docker-registry/](https://jfrog.com/blog/how-to-set-up-a-private-remote-and-virtual-docker-registry/)
