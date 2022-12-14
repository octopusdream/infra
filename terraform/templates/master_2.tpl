#!/bin/bash

sudo apt -y install net-tools
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su

sudo echo "alias k='kubectl'
alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

sudo echo "
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

###### AWS Controller Manager #####
# kustomize 설치
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.6/kustomize_v4.5.6_linux_amd64.tar.gz
gzip -d kustomize_v4.5.6_linux_amd64.tar.gz
tar xvf kustomize_v4.5.6_linux_amd64.tar
mv ./kustomize  /usr/bin

# 매니페스트 파일 설치
kustomize build 'github.com/kubernetes/cloud-provider-aws/examples/existing-cluster/overlays/superset-role/?ref=master' | kubectl apply -f -


#### ansible #####
sudo apt install -y ansible

sudo mkdir /etc/ansible
echo "worker1
worker2
worker3
worker4
worker5
worker6
" >> /etc/ansible/hosts
