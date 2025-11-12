#!/bin/bash
sudo yum update -y
sudo yum install -y curl unzip tar wget sed gcc* openssl-devel openssl krb5-workstation krb5-libs python-devel python java-1.8.0-openjdk-devel snappy openssh-server openssh-clients
sudo systemctl disable firewalld
sudo service firewalld stop
sudo setenforce 0
enabled=0
sudo sed -i '1i10.0.0.2   master\n10.0.0.3   worker1\n10.0.0.4   worker2\n10.0.0.5   worker3' /etc/hosts
echo "${public_ssh_key}" >> /root/.ssh/authorized_keys
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
sudo systemctl start chronyd
sudo systemctl enable chronyd
sudo wget -O- https://clemlabs.s3.eu-west-3.amazonaws.com/RPM-GPG-KEY-SHA256-Jenkins -O /tmp/RPM-GPG-KEY-SHA256-Jenkins
sudo rpm --import /tmp/RPM-GPG-KEY-SHA256-Jenkins
sudo wget -O /etc/yum.repos.d/odp.repo https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/odp-release/1.2.2.0-128/odp.repo
sudo wget -O /etc/yum.repos.d/ambari.repo https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/ambari-release/2.7.9.0.0-61/ambari.repo
sudo yum update -y
sudo yum install odp-select.aarch64 -y
sudo yum install ambari-agent.aarch64 -y
sed -i 's/localhost/master/' /etc/ambari-agent/conf/ambari-agent.ini
sudo ambari-agent start
sudo useradd console
sudo usermod -aG wheel console
echo "console:1aB@2bC#" | sudo chpasswd