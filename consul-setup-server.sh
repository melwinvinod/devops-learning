#!/bin/bash

sudo cd /opt
sudo apt install -y unzip
sudo wget https://releases.hashicorp.com/consul/1.11.2/consul_1.11.2_linux_amd64.zip
sudo unzip consul_1.11.2_linux_amd64.zip
sudo rm consul_1.11.2_linux_amd64.zip
sudo cp consul /usr/bin

{
sudo tee -a  /etc/systemd/system/consul.service > /dev/null <<EOT
[Unit]
Description=Consul Server
Documentation=https://www.consul.io/docs
After=network.target

[Service]
ExecStart=/usr/bin/consul agent -dev -client=0.0.0.0 -bind=0.0.0.0
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOT
}

sudo systemctl daemon-reload
sudo systemctl start consul.service
sudo systemctl enable consul.service
