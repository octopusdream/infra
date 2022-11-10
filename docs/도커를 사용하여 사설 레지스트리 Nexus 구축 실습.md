## 사전 준비 사항

Ubuntu 버전 : 20.04.5

docker 버전 : 20.10.18

## 도커를 사용하여 사설 저장소 Nexus 구축

### **Nexus Data 저장 공간 생성**

```bash
root@master:~# mkdir /data
# UID/GID 는 200 으로 설정
root@master:~# chown 200:200 /data
```

### Nexus **container 시작**

```bash
root@master:~# docker run -d --restart=always -p 8081:8081 -p 5001:5001 \
--name nexus -v /data:/nexus-data sonatype/nexus3
```

### 웹 상에서 접근 & 로그인

```bash
# 초반 admin 비밀번호
root@master:~# cat /data/admin.password
bdb8744c-7cbd-46c4-a0e3-d6645288c3d1
```

![image](https://user-images.githubusercontent.com/93571332/201016163-08a5c54c-57c1-481d-90a3-a535b8d6895a.png)

![image](https://user-images.githubusercontent.com/93571332/201016199-cacc9a46-d3c3-4fd9-b9c3-4bc66c6755dc.png)

admin 비밀번호 재설정 (Test$123)

![image](https://user-images.githubusercontent.com/93571332/201016237-4d155a1f-ce9b-4872-8f7f-629517630110.png)

anonymous 계정 활성화

![image](https://user-images.githubusercontent.com/93571332/201016276-b72d3378-96b5-46fa-9e17-cda147ef6918.png)

![image](https://user-images.githubusercontent.com/93571332/201016302-f9bfb201-3047-429a-900f-3307c38cea02.png)

### 사설 컨테이너 이미지 저장소 생성

![image](https://user-images.githubusercontent.com/93571332/201016450-09a790dc-7919-4850-a745-adc1f482f1c2.png)

![image](https://user-images.githubusercontent.com/93571332/201016473-f73a228a-1332-4edf-b044-96f46781b43c.png)

![image](https://user-images.githubusercontent.com/93571332/201016491-4aa9252c-da4d-43c3-a395-c308ee5960f8.png)

Repository 이름 지정하고, Repository에 사용할 Port 지정

HTTPS Port, Docker V1 API 활성화, 익명 사용자 Pull 권한 등 설정

(anonymous Pull 기능 필요하다면, Realms 에서 Docker Bearer Token Realm 추가)

![image](https://user-images.githubusercontent.com/93571332/201016535-2bc5d435-0988-4856-a042-197004be44d1.png)

![image](https://user-images.githubusercontent.com/93571332/201016546-b26144d4-e2ac-49e5-aeed-45dff99680a3.png)

### 컨테이너 이미지 push

현재 접속은 https 가 아닌 http 로의 접속이므로 이를 허용해 주어야 한다. 

아래와 같이 비보안 접속 허용을 위한 구성을 모든 노드에 적용

```bash
root@master:~# vi /etc/docker/daemon.json
{
	"insecure-registries" : [ "192.168.8.100:5001" ]
}
root@master:~# systemctl restart docker
root@master:~# docker login
```

도커 로그인 실행

```bash
root@master:~# docker login 192.168.8.100:5001
Username: admin
Password:
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

tag 수정 및 container image push

```bash
root@master:~# docker tag brian24/testweb:green 192.168.8.100:5001/green:1.0
root@master:~# docker push 192.168.8.100:5001/green:1.0
```

UI에서 확인

![image](https://user-images.githubusercontent.com/93571332/201016590-d364190c-8de8-4e07-b399-4b74839404a2.png)

### 참고

[https://chhanz.github.io/devops/2020/04/17/install-nexus-ce/](https://chhanz.github.io/devops/2020/04/17/install-nexus-ce/)

[https://blog.sonatype.com/using-nexus-3-as-your-repository-part-3-docker-images](https://blog.sonatype.com/using-nexus-3-as-your-repository-part-3-docker-images)
