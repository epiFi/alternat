#!/bin/bash

# ABOUT: this script installs the prometheus-node-exporter
# as a systemd service on the system

export SERVICE_USER="node_exporter"
export CONFIG_DIR="/etc/node-exporter"
export VERSION="1.6.1"

# download and install binary

mkdir /tmp/download
cd /tmp/download
wget "https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz"
tar xzf node_exporter-${VERSION}.linux-amd64.tar.gz
cp node_exporter-${VERSION}.linux-amd64/node_exporter /usr/local/sbin/

# create service user and group

adduser --system --no-create-home --group ${SERVICE_USER}

# create config

mkdir ${CONFIG_DIR}

cat >${CONFIG_DIR}/node_exporter_env <<EOL
OPTIONS="--collector.textfile.directory /var/lib/node_exporter/textfile_collector --collector.tcpstat --collector.systemd --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/)"
EOL

chown -R ${SERVICE_USER}:${SERVICE_USER} ${CONFIG_DIR}
chmod 0644 ${CONFIG_DIR}/node_exporter_env

# create data dir

mkdir -p /var/lib/node_exporter/textfile_collector
chown -R ${SERVICE_USER}:${SERVICE_USER} /var/lib/node_exporter

# create service dependency - socket

cat >/etc/systemd/system/node_exporter.socket <<EOL
[Unit]
Description=Node Exporter

[Socket]
ListenStream=9100

[Install]
WantedBy=sockets.target
EOL

chown root:root /etc/systemd/system/node_exporter.socket
chmod 0644 /etc/systemd/system/node_exporter.socket

# create systemd service unit

cat >/etc/systemd/system/node_exporter.service <<EOL
[Unit]
Description=Node Exporter
Requires=node_exporter.socket

[Service]
User=node_exporter
EnvironmentFile=/etc/node-exporter/node_exporter_env
ExecStart=/usr/local/sbin/node_exporter --web.systemd-socket $OPTIONS

[Install]
WantedBy=multi-user.target
EOL

chown root:root /etc/systemd/system/node_exporter.service
chmod 0644 /etc/systemd/system/node_exporter.service

# enable and start systemd service

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
