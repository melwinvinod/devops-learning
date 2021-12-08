#!/bin/bash

echo '''
###################################################
########## KUBEADM SETUP FOR MASTER NODE ##########
###################################################
'''

if [ $? -eq 0 ]
then
	echo -e "\n ########## STARTING EXECUTION ########## \n"
else
	echo -e "\n ########## SCRIPT EXECUTION FAILED, CHECK ERRORS ABOVE ########## \n"
fi

echo -e "##########################################################\n"
echo -e "########## Letting iptables see bridged traffic ########## \n"
echo -e "##########################################################\n"
sudo modprobe br_netfilter

echo -e "##########################################################\n"
echo -e "########## Ensure net.bridge.bridge-nf-call-iptables is set to 1 in your sysctl config ########## \n"
echo -e "##########################################################\n""

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

echo -e "##########################################################\n"
echo -e "########## Install DOCKER using repository method ########## \n"
echo -e "########## Set up the repository ########## \n"
echo -e "##########################################################\n"

sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


echo -e "##########################################################\n"
echo -e "########## Disabling swap ########## \n"
echo -e "##########################################################\n"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


echo -e "##########################################################\n"
echo -e "########## Install Docker Runtime Engine ########## \n"
echo -e "##########################################################\n"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo -e "##########################################################\n"
echo -e "########## Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups. [overlay2] is the preferred storage driver for systems running Linux kernel version 4.0 or higher, or RHEL or CentOS using version 3.10.0-514 and above. ########## \n"
echo -e "##########################################################\n"


sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo -e "##########################################################\n"
echo -e "########## Restart Docker and enable on boot ##########\n"
echo -e "##########################################################\n"

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
echo -e '\n ########## Docker should be up and running now ########## \n'


echo -e "##########################################################\n"
echo -e "\n ########## Setting up packages for kubeadm, kubelet and kubectl now ########## \n"
echo -e "##########################################################\n"

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo -e "##########################################################\n"
echo -e "Update apt package index, install kubelet, kubeadm and kubectl, and pin their version"
echo -e "##########################################################\n"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl start kubelet

if [ $? -eq 0 ]
then
	echo -e "\n ########## KUBELET STARTED SUCCESSFULLY ########## \n"
else
	echo -e "\n ########## KUBELET FAILED TO START, START THE SERVICE AND CHECK ########## \n"
	exit 1
fi



echo; echo; echo; echo; echo; echo; echo; echo

echo -e "##########################################################\n"
echo -e "########## Initializing KUBEADM ########## \n\n"
echo -e "##########################################################\n"

sudo kubeadm init

echo; echo; echo; echo; echo; echo; echo; echo


echo -e "##########################################################\n"
echo -e "Running the above 3 dir creation commands as regular user\n"
echo -e "##########################################################\n"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo -e "##########################################################\n"
echo -e "########## INSTALLING the networking addon - WEAVE NET ########## \n" 
echo -e "##########################################################\n"

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
if [ $? -ne 0 ]
then
	echo -e "\n >>>>> Networking plugin installation failed..Try to install manually <<<<< \n"
else
	echo -e "\n >>>>> Network plugin installed successfully  <<<<< \n"
fi

echo -e "##########################################################\n"
echo -e "Run the kubeadm join command shown above on the worker nodes as root  \n"
echo -e "In case the token is not visible, run \t  kubeadm token create --print-join-command \n"
echo -e "##########################################################\n"
