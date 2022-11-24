#!/bin/bash

sudo apt -y install net-tools vim
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su

sudo echo "alias k='kubectl'
alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

sudo echo "
${master2_ip}  master2
${master3_ip}  master3
${worker1_ip}  worker1
${worker2_ip}  worker2
${worker3_ip}  worker3
${worker4_ip}  worker4
${worker5_ip}  worker5
${worker6_ip}  worker6
" >> /etc/hosts


sudo echo "
Host worker1
	Hostname worker1
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

Host worker2
	Hostname worker2
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

Host worker3
	Hostname worker3
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

Host worker4
	Hostname worker4
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

Host worker5
	Hostname worker5
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

Host worker6
	Hostname worker6
	IdentityFile ~/.ssh/kakaokey
	User ubuntu
" >> ~/.ssh/config

sudo touch  ~/.ssh/kakaokey
echo "${key_pem}" > ~/.ssh/kakaokey
sudo chmod 600 ~/.ssh/kakaokey

ssh-keyscan master2 >> ~/.ssh/known_hosts
ssh-keyscan master3 >> ~/.ssh/known_hosts
ssh-keyscan worker1 >> ~/.ssh/known_hosts
ssh-keyscan worker2 >> ~/.ssh/known_hosts
ssh-keyscan worker3 >> ~/.ssh/known_hosts
ssh-keyscan worker4 >> ~/.ssh/known_hosts
ssh-keyscan worker5 >> ~/.ssh/known_hosts
ssh-keyscan worker6 >> ~/.ssh/known_hosts


# 방화벽 종료
sudo systemctl stop ufw && systemctl disable ufw

# apt 패키지 업데이트 및 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# swap 종료
sudo swapoff -a
sudo echo 0 > /proc/sys/vm/swappiness
sudo sed -e '/swap/ s/^#*/#/' -i /etc/fstab


##### docker #####
# 1. 도커설치를 위한 GPG 키 다운로드
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 2. 도커 리파지토리 추가
echo "\n" | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 3. docker-ce 버전 설치
sudo apt-get install -y docker-ce=5:20.10.17~3-0~ubuntu-$(lsb_release -cs)


##### kubeadm, kubelet 및 kubectl #####
# 1. 쿠버네티스를 설치를 위한 GPG 키 다운로드
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# 2. k8s 저장소 추가
sudo cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# 3. 저장소 업데이트
sudo apt-get update

# 4. k8s 1.21 버전 설치
sudo apt-get install -y kubelet=1.21.1-00 kubeadm=1.21.1-00 kubectl=1.21.1-00

# 5. 업그레이드로 인한 버전업 방지
sudo apt-mark hold docker-ce kubelet kubeadm kubectl


# ##### kubeadm init ###
echo "# control-plane.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  extraArgs:
    authorization-mode: Node,RBAC
    cloud-provider: aws  # cloud-provider 옵션 추가
  timeoutForControlPlane: 4m0s
certificatesDir: /etc/kubernetes/pki
clusterName: jordy  # 태그에 지정할 클러스터 이름을 명시
controlPlaneEndpoint: ""
controllerManager:
  extraArgs:
    cloud-provider: aws  # cloud-provider 옵션 추가
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io

networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: aws  # cloud-provider 옵션 추가" > control-plane.yaml
kubeadm init --config control-plane.yaml

mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown 0:0 /root/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf


##### kubeadm join #####
while :
do
  ip a
  if [ $?==0 ]; then
    break
  else
    sleep 1
  fi
done

echo -n "#!" > /home/ubuntu/worker.sh
sudo echo "/bin/bash

# worker.yaml
sudo echo \"apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $(sudo kubeadm token list | cut -d ' ' -f 1 | sed '1d') # token 값
    apiServerEndpoint: \\\"$(ip a | grep '10.0.3.' | cut -d ' ' -f 6 | cut -d '/' -f 1):6443\\\" # HA가 구축되지 않은 경우
    caCertHashes:
      - sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //') # hash 값
nodeRegistration:
  name: ip-10-0-\$(ip a | grep '10.0.' | cut -d ' ' -f 6 | cut -d '/' -f 1 | cut -d '.' -f 3)-\$(ip a | grep '10.0.' | cut -d ' ' -f 6 | cut -d '/' -f 1 | cut -d '.' -f 4).ap-northeast-3.compute.internal # worker hostname
  kubeletExtraArgs:
    cloud-provider: aws  # cloud-provider 옵션 추가\" > worker.yaml

sudo kubeadm join --config worker.yaml
" >> /home/ubuntu/worker.sh

File=/home/ubuntu/worker.sh
while :
do
  if [ -f "$File" ]; then
  	sudo scp /home/ubuntu/worker.sh ubuntu@worker1:/home/ubuntu/worker.sh
	sleep 1
	sudo scp /home/ubuntu/worker.sh ubuntu@worker2:/home/ubuntu/worker.sh
	sleep 1
	sudo scp /home/ubuntu/worker.sh ubuntu@worker3:/home/ubuntu/worker.sh
	sleep 1
	sudo scp /home/ubuntu/worker.sh ubuntu@worker4:/home/ubuntu/worker.sh
	sleep 1
	sudo scp /home/ubuntu/worker.sh ubuntu@worker5:/home/ubuntu/worker.sh
	sleep 1
	sudo scp /home/ubuntu/worker.sh ubuntu@worker6:/home/ubuntu/worker.sh
	sleep 1

	sudo ssh ubuntu@worker1 "sh worker.sh"
	sleep 1
	sudo ssh ubuntu@worker2 "sh worker.sh"
	sleep 1
	sudo ssh ubuntu@worker3 "sh worker.sh"
	sleep 1
	sudo ssh ubuntu@worker4 "sh worker.sh"
	sleep 1
	sudo ssh ubuntu@worker5 "sh worker.sh"
	sleep 1
	sudo ssh ubuntu@worker6 "sh worker.sh"
	sleep 1
    break
  else
    sleep 1
  fi
done


###### AWS Controller Manager #####
# kustomize 설치
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.6/kustomize_v4.5.6_linux_amd64.tar.gz
gzip -d kustomize_v4.5.6_linux_amd64.tar.gz
tar xvf kustomize_v4.5.6_linux_amd64.tar
mv ./kustomize  /usr/bin

# 매니페스트 파일 설치
kustomize build 'github.com/kubernetes/cloud-provider-aws/examples/existing-cluster/overlays/superset-role/?ref=master' | kubectl apply -f -


##### calico #####
sudo kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

##### calicoctl #####
# 현재 경로에 calicoctl binary 다운로드
sudo curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.17.1/calicoctl

# +x 모드 추가 
sudo chmod +x calicoctl

# 아무 경로에서 사용 가능하도록 PATH에 등록된 곳(ex: /usr/local/bin)으로 파일 이동
sudo mv calicoctl /usr/local/bin


# ippool manifast 수정
# .spec.ipipMode를 'Always'로 변경시, ipip Mode가 활성화
sudo echo "apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
name: default-ipv4-ippool
spec:
blockSize: 26
cidr: 192.168.0.0/16
#   ipipMode: Always
ipipMode: CrossSubnet
natOutgoing: true
nodeSelector: all()
vxlanMode: Never" > ~/calico-ipool.yaml
sudo calicoctl apply -f ~/calico-ipool.yaml

##### ansible #####
sudo apt install -y ansible
sudo mkdir /etc/ansible
echo "worker1
worker2
worker3
worker4
worker5
worker6
" >> /etc/ansible/hosts

##### delete ######
sudo rm -rf ~/token_file
sudo rm -rf ~/token_file_2
# sudo rm -rf /home/ubuntu/worker.sh
sudo rm -rf ~/calico-ipool.yaml
