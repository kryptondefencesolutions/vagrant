#!/bin/bash
set -x

export DEBIAN_FRONTEND=noninteractive
sudo timedatectl set-timezone Europe/London
if [ -e /etc/redhat-release ] ; then
  REDHAT_BASED=true
fi

RUBY_VERSION="2.3.1p112"
TERRAFORM_VERSION="0.11.14"
PACKER_VERSION="1.3.2"
ANSIBLE_VERSION="2.6.7"
RKE_VERSION="v0.1.15"
NJ_VERSION="11"
KOPS_VERSION="1.14.0"
JX_VERSION="2.0.152"
# create new ssh key
[[ ! -f /home/ubuntu/.ssh/mykey ]] \
&& mkdir -p /home/ubuntu/.ssh \
&& ssh-keygen -f /home/ubuntu/.ssh/mykey -N '' \
&& chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# move synced localhost keys to .ssh
cp /home/vagrant/.ssh/keys/* /home/vagrant/.ssh/
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 400 /home/vagrant/.ssh/*.pem
# IdentityFile ~/.ssh/identity

# install packages
if [ ${REDHAT_BASED} ] ; then
  yum -y update
  yum install -y docker unzip wget jq
else
  apt-get update
  apt-get -y install docker.io unzip wget jq python-pip tree ntpdate
fi
# add docker privileges
usermod -G docker ubuntu
usermod -G docker vagrant

# install awscli, ebcli, aws2fa and ansible
pip install -U awscli
pip install -U awsebcli
pip install -U ansible==${ANSIBLE_VERSION}
pip install -U aws2fa

# kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# kops
KS_VERSION=$(/usr/local/bin/kops version|head -1 |cut -d ' ' -f 2 |tail -c +1)
KS_RETVAL=$?
[[ $KS_VERSION != $KOPS_VERSION ]] || [[ $KS_RETVAL != 1 ]] \
&& curl -LO https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}-alpha.1/kops-linux-amd64 \
&& chmod +x kops-linux-amd64 \
&& mv ./kops-linux-amd64 /usr/local/bin/kops

# jx
#mkdir -p ~/.jx/bin
#curl -L https://github.com/jenkins-x/jx/releases/download/v${JX_VERSION}/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin
#export PATH=$PATH:~/.jx/bin
#echo 'export PATH=$PATH:~/.jx/bin' >> ~/.bashrc

# jenkinsX
#curl -L https://github.com/jenkins-x/jx/releases/latest/download/jx-linux-amd64.tar.gz | tar xzv
#s#udo mv jx /usr/local/bin

# JX_VERSION=$(/home/vagrant/.jx/bin/jx version| head -1 | cut -d ' ' -f 2 | tail -c +1)
# JX_RETVAL=$?
#
# [[ $JX_VERSION != $JX_VERSION ]] || [[ $JX_RETVAL != 1 ]] \
# && mkdir -p ~/.jx/bin \
# && curl -L https://github.com/jenkins-x/jx/releases/download/v${JX_VERSION}/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin \
# && export PATH=$PATH:~/.jx/bin \
# && echo 'export PATH=$PATH:~/.jx/bin' >> ~/.bashrc

# rke
RK_VERSION=$(/usr/bin/rke -version| head -1 | cut -d ' ' -f 2 | tail -c +1)
RK_RETVAL=$?

[[ $RK_VERSION != $RKE_VERSION ]] || [[ $RK_RETVAL != 1 ]] \
&& sudo wget https://github.com/rancher/rke/releases/download/${RKE_VERSION}/rke_linux-amd64 -O /usr/bin/rke \
&& sudo chmod +x /usr/bin/rke
# && sudo mv rke_linux_amd64 /usr/bin/rke \

# npm and nodejs version 7.x
NJ_VERSION=$(/usr/bin/nodejs --version| head -1 | cut -d ' ' -f 2 | tail -c +2)
NJ_RETVAL=$?

[[ $NJ_VERSION != $NJ_VERSION ]] || [[ $NJ_RETVAL != 1 ]] \
&& curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash - \
&& sudo apt-get install -y nodejs

#ruby
R_VERSION=$(/usr/bin/ruby -v| head -1 | cut -d ' ' -f 2 | tail -c +1)
R_RETVAL=$?

[[ $R_VERSION != $RUBY_VERSION ]] || [[ $R_RETVAL != 1 ]] \
&& sudo apt-get install -y ruby-full


#terraform
T_VERSION=$(/usr/local/bin/terraform -v | head -1 | cut -d ' ' -f 2 | tail -c +2)
T_RETVAL=${PIPESTATUS[0]}

[[ $T_VERSION != $TERRAFORM_VERSION ]] || [[ $T_RETVAL != 0 ]] \
&& wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# packer
P_VERSION=$(/usr/local/bin/packer -v)
P_RETVAL=$?

[[ $P_VERSION != $PACKER_VERSION ]] || [[ $P_RETVAL != 1 ]] \
&& wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
&& unzip -o packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm packer_${PACKER_VERSION}_linux_amd64.zip

# clean up
if [ ! ${REDHAT_BASED} ] ; then
  apt-get clean
fi
