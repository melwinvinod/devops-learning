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
echo -e "\n--Alert Manager will be downloaded to /usr/bin/alertmanager-server/alertmanager"
echo -e "\n--Alert Manager will use the above directory as the working directory"

echo -e "\n ############### DOWNLOAD Alert Manager ###############"
cd /usr/bin/
mkdir alertmanager-server && cd $_
wget https://github.com/prometheus/alertmanager/releases/download/v0.23.0/alertmanager-0.23.0.linux-amd64.tar.gz
tar -xf alertmanager*.tar.gz
rm alertmanager*.tar.gz
mv alertmanager* alertmanager

echo -e "\n ############### Service file ###############"
cat <<EOF >/etc/systemd/system/alertmanager.service
[Unit]
Description=Alertmanager Server
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
ExecStart=/usr/bin/alertmanager-server/alertmanager/alertmanager --config.file=/usr/bin/alertmanager-server/alertmanager/alertmanager.yml

[Install]
WantedBy=multi-user.target
EOF


echo -e "\n ############### TO BE RUN AFTER SERVICE IS CONFIGURED ###############"
systemctl daemon-reload
systemctl start alertmanager.service
systemctl enable alertmanager.service


echo -e "\n ############### SCRIPT EXECUTION DONE | Check the status by running systemctl status alertmanager.service ###############"
response=$(curl --write-out "%{http_code}\n" --silent --max-time 10 --output /dev/null "$(curl -s ifconfig.me):9093/#/alerts")
if [ $response == 200 ]
then
    echo -e "\n Alertmanager server is up and reachable at $(curl -s ifconfig.me):9093/#/alerts \n"

else
	echo -e "\n Alertmanager is not reachable. Please check if port 9093 is accessible \n"
fi
}

_check_root
exit 0
