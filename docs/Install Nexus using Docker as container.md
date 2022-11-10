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

![image](https://user-images.githubusercontent.com/93571332/201015996-9775c3ee-5db3-43c1-99f6-1fb588b53f80.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/93f5c854-5d68-4537-960b-1f29e4827183/Untitled.png)

admin 비밀번호 재설정 (Test$123)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a3c90bf1-0551-40fb-8a27-fc56999b78b8/Untitled.png)

anonymous 계정 활성화

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8e1211ad-6784-4526-9962-487a96360a77/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/27a46b4d-83b7-40a8-993a-093f94798864/Untitled.png)

### 사설 컨테이너 이미지 저장소 생성

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a5167658-73f0-4690-9485-1132aaf835f9/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/9020c064-7c26-465b-bb09-fdc15d613816/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/f15dc133-07e2-4149-abc1-f9c31c4474eb/Untitled.png)

Repository 이름 지정하고, Repository에 사용할 Port 지정

HTTPS Port, Docker V1 API 활성화, 익명 사용자 Pull 권한 등 설정

(anonymous Pull 기능 필요하다면, Realms 에서 Docker Bearer Token Realm 추가)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/97135399-9a6c-4419-99a2-b3104474d15b/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/c1534838-7931-4a84-a317-63d004202fa6/Untitled.png)

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

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/c1d9717f-6750-48e7-86e0-5570f49fcf33/Untitled.png)

### 참고

[https://chhanz.github.io/devops/2020/04/17/install-nexus-ce/](https://chhanz.github.io/devops/2020/04/17/install-nexus-ce/)

[https://blog.sonatype.com/using-nexus-3-as-your-repository-part-3-docker-images](https://blog.sonatype.com/using-nexus-3-as-your-repository-part-3-docker-images)
