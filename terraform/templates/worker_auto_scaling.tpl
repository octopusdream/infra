#!/bin/bash

sudo apt -y install net-tools vim
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su

sudo echo "alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

sudo su -
sudo mkdir /efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0f6b2f5b9a24e90d1.efs.ap-northeast-3.amazonaws.com:/ /efs
df -h
touch /efs/kakao
ls /efs

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

# ssh 연결
sudo echo "10.0.3.100  master1
10.0.4.100  master2
10.0.5.100  master3
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

touch ~/.ssh/kakaokey
echo "${key_pem}" > ~/.ssh/kakaokey
chmod 600 ~/.ssh/kakaokey

ssh-keyscan master1 >> ~/.ssh/known_hosts
ssh-keyscan master2 >> ~/.ssh/known_hosts
ssh-keyscan master3 >> ~/.ssh/known_hosts

while :
do
  ip a
  if [ $?==0 ]; then
    break
  else
    sleep 1
  fi
done


# health check
# 살아있는 master에서 파일 가져와서 실행
rm -rf /home/ubuntu/worker.sh

echo > /dev/tcp/master1/6443
if [ $? -eq 1 ]; then
  echo > /dev/tcp/master2/644
  if [ $? -eq 1 ]; then
    if [ -z $(ssh master3 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
      sudo ssh master3 "sudo kubeadm token create"
    fi
    sudo scp ubuntu@master3:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
    sleep 1
    sed -i 's/master1/master3/g' /home/ubuntu/worker.sh
  else
    if [ -z $(ssh master2 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
      sudo ssh master2 "sudo kubeadm token create"
    fi
    sudo scp ubuntu@master2:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
    sleep 1
    sed -i 's/master1/master2/g' /home/ubuntu/worker.sh
  fi
else
  if [ -z $(ssh master1 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
    sudo ssh master1 "sudo kubeadm token create"
  fi
  sudo scp ubuntu@master1:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
  sleep 1
fi

File=/home/ubuntu/worker.sh
while :
do
  if [ -f "$File" ]; then
    bash /home/ubuntu/worker.sh
    break
  else
    sleep 1
  fi
done

sed -i 's/master2/master1/g' /home/ubuntu/master.sh
sed -i 's/master3/master1/g' /home/ubuntu/master.sh

