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
echo -e "\n--Prometheus will be downloaded to /usr/bin/prometheus-server/prometheus"
echo -e "\n--Prometheus will use the above directory as the working directory"

echo -e "\n ############### DOWNLOAD PROMETHEUS ###############"
cd /usr/bin/
mkdir prometheus-server && cd $_
wget https://github.com/prometheus/prometheus/releases/download/v2.32.0-rc.0/prometheus-2.32.0-rc.0.linux-amd64.tar.gz
tar -xf prometheus*.tar.gz
rm prometheus*.tar.gz
mv prom* prometheus
rm /usr/bin/prometheus-server/prometheus/prometheus.yml
wget -q https://raw.githubusercontent.com/melwinvinod/devops-learning/main/prometheus.yml -O /usr/bin/prometheus-server/prometheus/prometheus.yml
wget -q https://raw.githubusercontent.com/melwinvinod/devops-learning/main/my_rules.yml -O /usr/bin/prometheus-server/prometheus/my_rules.yml

#Setup Cron which pulls the rules file from git every 1 mins
crontab -l | { cat; echo "* * * * * bash <( curl https://raw.githubusercontent.com/melwinvinod/devops-learning/main/update-alerting-rules-prometheus.sh) > /usr/bin/prometheus-server/prometheus/cron-output-for-update-alerting-rules-prometheus.txt
"; } | crontab -

echo -e "\n ############### Service file ###############"
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
ExecStart=/usr/bin/prometheus-server/prometheus/prometheus --web.enable-lifecycle --config.file=/usr/bin/prometheus-server/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n ############### TO BE RUN AFTER SERVICE IS CONFIGURED ###############"
systemctl daemon-reload
systemctl start prometheus.service
systemctl enable prometheus.service


echo -e "\n ############### SCRIPT EXECUTION DONE | Check the status by running systemctl status prometheus.service ###############"
response=$(curl --write-out "%{http_code}\n" --silent --max-time 10 --output /dev/null "$(curl -s ifconfig.me):9090/graph")
if [ $response == 200 ]
then
    echo -e "\n Prometheus server is up and reachable at $(curl -s ifconfig.me):9090 \n"

else
	echo -e "\n Prometheus is not reachable. Please check if port 9090 is accessible \n"
fi
}

_check_root
exit 0
