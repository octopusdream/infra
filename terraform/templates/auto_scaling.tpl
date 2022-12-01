#!/bin/bash

sudo apt -y install net-tools vim
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su

sudo echo "alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

sudo su -
sudo mkdir /efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns_name}:/ /efs
df -h
touch /efs/kakao
# ls /efs
sudo echo "${efs_dns_name}:/    /efs    nfs4    _netdev,tls     0   0" >> /etc/fstab


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

sudo echo "${master1_ip}  master1
${master2_ip}  master2
${master3_ip}  master3
" >> /etc/hosts

sudo echo "Host master1
	Hostname master1
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

  Host master2
	Hostname master2
	IdentityFile ~/.ssh/kakaokey
	User ubuntu

  Host master3
	Hostname master3
	IdentityFile ~/.ssh/kakaokey
	User ubuntu
" >> ~/.ssh/config

sudo touch  ~/.ssh/kakaokey
echo "${key_pem}" > ~/.ssh/kakaokey
sudo chmod 600 ~/.ssh/kakaokey

ssh-keyscan master1 >> ~/.ssh/known_hosts
ssh-keyscan master2 >> ~/.ssh/known_hosts
ssh-keyscan master3 >> ~/.ssh/known_hosts

sudo scp ubuntu@master1:/home/ubuntu/worker.sh /home/ubuntu/worker.shubuntu
# if [ -f /home/worker.sh]
# sudo scp ubuntu@master1:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
# sudo scp ubuntu@master1:/home/ubuntu/worker.sh /home/ubuntu/worker.sh

# echo -n "#!" > /home/ubuntu/worker.sh
# sudo echo "/bin/bash

# # worker.yaml
# sudo echo \"apiVersion: kubeadm.k8s.io/v1beta2
# kind: JoinConfiguration
# discovery:
#   bootstrapToken:
#     token: $(ssh master1 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1") # token 값
#     apiServerEndpoint: \"${master_nlb_dns_name}:6443\"
#     caCertHashes: [\"sha256:$(ssh $MASTER "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")\"]  # hash 값
# nodeRegistration:
#   name: \$(curl -s http://169.254.169.254/latest/meta-data/local-hostname) # worker hostname
#   kubeletExtraArgs:
#     cloud-provider: aws  # cloud-provider 옵션 추가\" > /home/ubuntu/worker.yaml

# sudo kubeadm join --config /home/ubuntu/worker.yaml" >> /home/ubuntu/worker.sh



while :
do
  ip a
  if [ $?==0 ]; then
    break
  else
    sleep 1
  fi
done

File=/home/ubuntu/worker.sh
while :
do
  if [ -f "$File" ]; then
    sudo sh /home/ubuntu/worker.sh
    break
  else
    sleep 1
  fi
done
