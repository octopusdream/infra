#!/bin/bash

sudo apt -y install net-tools vim
# sudo hostnamectl set-hostname master

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


##### kubeadm init ###
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tail -n 2 >> ~/token_file
sudo echo "sudo $(cat ~/token_file)" > ~/token_file

mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown 0:0 /root/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf


##### kubeadm join #####
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker1
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker2
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker3
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker4
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker5
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker6
sleep 1


sudo echo "$(cat ~/token_file)
# mkdir -p /root/.kube
# sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
# sudo chown 0:0 /root/.kube/config
# export KUBECONFIG=/etc/kubernetes/admin.conf
" > ~/token_file_2

sudo cat ~/token_file_2 | ssh -i ~/.ssh/kakaokey ubuntu@master2
sleep 1
sudo cat ~/token_file_2 | ssh -i ~/.ssh/kakaokey ubuntu@master3
sleep 1


# ##### calico #####
sudo curl -O -L https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml -O
sudo kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


# ##### calicoctl #####
# 현재 경로에 calicoctl binary 다운로드
sudo curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.17.1/calicoctl
# +x 모드 추가 
sudo chmod +x calicoctl
# 아무 경로에서 사용 가능하도록 PATH에 등록된 곳(ex: /usr/local/bin)으로 파일 이동
sudo mv calicoctl /usr/local/bin
# #####################


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


#### ansible #####
sudo apt install -y ansible

# id_rsa
sudo ssh-keygen -q -f ~/.ssh/id_rsa -N ""
sudo chmod 600 ~/.ssh/id_rsa
sudo echo "sudo echo \"$(cat ~/.ssh/id_rsa.pub)\" > ~/.ssh/authorized_keys" > ~/token_file

sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker1
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker2
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker3
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker4
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker5
sleep 1
sudo cat ~/token_file | ssh -i ~/.ssh/kakaokey ubuntu@worker6
sleep 1

ssh-keyscan worker1 > ~/.ssh/known_hosts
ssh-keyscan worker2 >> ~/.ssh/known_hosts
ssh-keyscan worker3 >> ~/.ssh/known_hosts
ssh-keyscan worker4 >> ~/.ssh/known_hosts
ssh-keyscan worker5 >> ~/.ssh/known_hosts
ssh-keyscan worker6 >> ~/.ssh/known_hosts


sudo mkdir /etc/ansible
echo "worker1
worker2
worker3
worker4
worker5
worker6
" >> /etc/ansible/hosts


sudo echo "
Host worker1
	Hostname worker1
	IdentityFile ~/.ssh/id_rsa
	User ubuntu

Host worker2
	Hostname worker2
	IdentityFile ~/.ssh/id_rsa
	User ubuntu

Host worker3
	Hostname worker3
	IdentityFile ~/.ssh/id_rsa
	User ubuntu

Host worker4
	Hostname worker4
	IdentityFile ~/.ssh/id_rsa
	User ubuntu

Host worker5
	Hostname worker5
	IdentityFile ~/.ssh/id_rsa
	User ubuntu

Host worker6
	Hostname worker6
	IdentityFile ~/.ssh/id_rsa
	User ubuntu
" >> ~/.ssh/config

sudo rm -rf ~/.ssh/kakaokey
sudo rm -rf ~/token_file
sudo rm -rf ~/token_file_2
rm -rf calico-ipool.yaml
