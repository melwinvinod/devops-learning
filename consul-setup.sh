#!/bin/bash
sudo -i
cd /opt
apt install -y unzip
wget https://releases.hashicorp.com/consul/1.11.2/consul_1.11.2_linux_amd64.zip
unzip consul_1.11.2_linux_amd64.zip
rm consul_1.11.2_linux_amd64.zip
cp consul /usr/bin

{
tee -a  /etc/systemd/system/consul.service > /dev/null <<EOT
[Unit]
Description=Consul Server
Documentation=https://www.consul.io/docs
After=network.target

[Service]
ExecStart=/usr/sbin/sshd -D $SSHD_OPTS
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOT
}

systemctl daemon-reload
systemctl start consul.service
systemctl enable consul.service
