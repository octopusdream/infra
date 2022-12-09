#!/bin/bash

sudo apt -y install net-tools
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su

sudo echo "alias k='kubectl'
alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

sudo echo "
10.0.3.100  master1
10.0.4.100  master2
10.0.5.100  master3
${worker1_ip}  worker1
${worker2_ip}  worker2
${worker3_ip}  worker3
${worker4_ip}  worker4
${worker5_ip}  worker5
${worker6_ip}  worker6
" >> /etc/hosts

sudo echo "
Host master1
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

ssh-keyscan master1 >> ~/.ssh/known_hosts
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
echo > /dev/tcp/master1/6443
if [ $? -eq 1 ]; then
  echo > /dev/tcp/master2/6443
  if [ $? -eq 1 ]; then
    if [ -z $(ssh master3 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
      sudo ssh master3 "sudo kubeadm token create"
    fi
    MASTER="master3"
    sudo scp ubuntu@master3:/home/ubuntu/master.sh /home/ubuntu/master.sh
    sleep 1
    sudo scp ubuntu@master3:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
    sleep 1
    sudo scp ubuntu@master3:/home/ubuntu/control-plane.yaml /home/ubuntu/control-plane.yaml
    sleep 1
    sed -i 's/master1/master3/g' /home/ubuntu/master.sh
  elif [ $(ip a | grep 10.0. | cut -d ' ' -f6 | cut -d '/' -f1 | cut -d '.' -f 3) -ne 4 ]; then
    if [ -z $(ssh master2 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
      sudo ssh master2 "sudo kubeadm token create"
    fi
    MASTER="master2"
    sudo scp ubuntu@master2:/home/ubuntu/master.sh /home/ubuntu/master.sh
    sleep 1
    sudo scp ubuntu@master2:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
    sleep 1
    sudo scp ubuntu@master2:/home/ubuntu/control-plane.yaml /home/ubuntu/control-plane.yaml
    sleep 1
    sed -i 's/master1/master2/g' /home/ubuntu/master.sh
  fi
elif [ $(ip a | grep 10.0. | cut -d ' ' -f6 | cut -d '/' -f1 | cut -d '.' -f 3) -ne 3 ]; then
  if [ -z $(ssh master1 "sudo kubeadm token list | grep bootstrappers | cut -d ' ' -f 1 | tail -1") ]; then
    sudo ssh master1 "sudo kubeadm token create"
  fi
  MASTER="master1"
  sudo scp ubuntu@master1:/home/ubuntu/master.sh /home/ubuntu/master.sh
  sleep 1
  sudo scp ubuntu@master1:/home/ubuntu/worker.sh /home/ubuntu/worker.sh
  sleep 1
  sudo scp ubuntu@master1:/home/ubuntu/control-plane.yaml /home/ubuntu/control-plane.yaml
  sleep 1
fi

APISERVER="etcd-$(ssh $MASTER "hostname")"
NEW_HOSTNAME=$(hostname)
ssh $MASTER "sudo kubectl -n kube-system exec $APISERVER -- sh -c \"ETCDCTL_API=3 etcdctl member list --cacert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/server.key --cert /etc/kubernetes/pki/etcd/server.crt\" | grep $NEW_HOSTNAME | cut -d ',' -f 1" > /home/ubuntu/etcd-id

File=/home/ubuntu/etcd-id
while :
do
  if [ -f "$File" ]; then
    ETCD_ID=$(cat /home/ubuntu/etcd-id)
    ssh $MASTER "sudo kubectl -n kube-system exec $APISERVER -- sh -c \"ETCDCTL_API=3 etcdctl member remove $ETCD_ID --cacert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/server.key --cert /etc/kubernetes/pki/etcd/server.crt\"" > /home/ubuntu/check
    break
  else
    sleep 1
  fi
done

File=/home/ubuntu/check
while :
do
  if [ -f "$File" ]; then
    break
  else
    sleep 1
  fi
done

File=/home/ubuntu/master.sh
while :
do
  if [ -f "$File" ]; then
    echo "y" | kubeadm reset
    sleep 10
    bash /home/ubuntu/master.sh
    break
  else
    sleep 1
  fi
done

sed -i 's/master2/master1/g' /home/ubuntu/master.sh
sed -i 's/master3/master1/g' /home/ubuntu/master.sh
rm -rf /home/ubuntu/check
rm -rf /home/ubuntu/etcd-id
rm -rf /home/ubuntu/cert-key

sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown 0:0 /root/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf


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
