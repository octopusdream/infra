#!/bin/bash

sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
sudo su
sudo apt -y install net-tools vim

sudo echo "alias vi='vim'" >> ~/.bashrc
sudo source ~/.bashrc

echo "${master1_ip}  master1
${master2_ip}  master2
${master3_ip}  master3
${worker1_ip}  worker1
${worker2_ip}  worker2
${worker3_ip}  worker3
${worker4_ip}  worker4
${worker5_ip}  worker5
${worker6_ip}  worker6
${jenkins_ip}  jenkins
" >> /etc/hosts

touch ~/.ssh/kakaokey
echo "${key_pem}" > ~/.ssh/kakaokey
chmod 600 ~/.ssh/kakaokey

ssh-keyscan master1 >> ~/.ssh/known_hosts
ssh-keyscan master2 >> ~/.ssh/known_hosts
ssh-keyscan master3 >> ~/.ssh/known_hosts
ssh-keyscan worker1 >> ~/.ssh/known_hosts
ssh-keyscan worker2 >> ~/.ssh/known_hosts
ssh-keyscan worker3 >> ~/.ssh/known_hosts
ssh-keyscan worker4 >> ~/.ssh/known_hosts
ssh-keyscan worker5 >> ~/.ssh/known_hosts
ssh-keyscan worker6 >> ~/.ssh/known_hosts
ssh-keyscan jenkins >> ~/.ssh/known_hosts

echo "
Host master1
	Hostname master1
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

Host master2
	Hostname master2
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

Host master3
	Hostname master3
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

Host jenkins
	Hostname jenkins
	IdentityFile ~/.ssh/kakaokey
	User ubuntu
" >> ~/.ssh/config

