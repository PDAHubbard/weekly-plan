#!/bin/bash

mkdir -p /tmp/node_exporter
cd /tmp/node_exporter

VERSION="1.8.2"

if [ $# -eq 1 ]
then
	VERSION=$1
fi	

DL_LINK=https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz

echo "Downloading node_exporter $VERSION: $DL_LINK"

curl -Lso node_exporter.tgz $DL_LINK

groupadd -f node_exporter
useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
mkdir -p /etc/node_exporter
chown node_exporter:node_exporter /etc/node_exporter

tar -zxf node_exporter.tgz 
cp node_exporter-$VERSION.linux-amd64/node_exporter /usr/bin
chown node_exporter:node_exporter /usr/bin/node_exporter

cat > node_exporter.service << HERE
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target
HERE

cp node_exporter.service /usr/lib/systemd/system/
chmod 664 /usr/lib/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

if curl -sf http://localhost:9100/metrics > /dev/null ;
then
	systemctl enable node_exporter
	cd -
	rm -rf /tmp/node_exporter
	exit 0
fi
systemctl status node_exporter
