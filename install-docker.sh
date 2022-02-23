#!/bin/bash

echo "\n Starting Script \n"
echo Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt-get update -y


sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release


echo -e "\n Add Docker’s official GPG key \n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


echo -e "\n Setup the stable repo \n"
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo -e "\n Update/refresh the repo \n"
sudo apt update

echo -e "\n Installing Docker \n"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo -e "\n Enable docker service\n"
sudo systemctl start docker
sudo systemctl enable docker
