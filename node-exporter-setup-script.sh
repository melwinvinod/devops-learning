#!/bin/bash


_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "Please run as root" >&2
        exit 1
    else
        _runscript
   fi
}

_runscript() {

echo -e "\n ############### NOTES ###############"
echo -e "\n--Node Exporter will be downloaded to /usr/bin/node_exporter/node_exporter"
echo -e "\n--Node Exporter will use the above directory as the working directory"

echo -e "\n ############### DOWNLOAD PROMETHEUS ###############"
cd /usr/bin/
mkdir node_exporter && cd $_
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar -xf node_exporter*.tar.gz
rm node_exporter*.tar.gz
mv node_exporter* node_exporter


echo -e "\n ############### Service file ###############"
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
ExecStart=/usr/bin/node_exporter/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF


echo -e "\n ############### TO BE RUN AFTER SERVICE IS CONFIGURED ###############"
systemctl daemon-reload
systemctl start node_exporter.service
systemctl enable node_exporter.service


echo -e "\n ############### SCRIPT EXECUTION DONE | Check the status by running systemctl status node_exporter.service ###############"
response=$(curl --write-out "%{http_code}\n" --silent --max-time 10 --output /dev/null "$(curl -s ifconfig.me):9100/metrics")
if [ $response == 200 ]
then
    echo -e "\n Node Exporter is up and reachable at $(curl -s ifconfig.me):9100/metrics \n"

else
	echo -e "\n Node Exporter is not reachable. Please check if port 9100 is accessible \n"
fi
}

_check_root
exit 0
