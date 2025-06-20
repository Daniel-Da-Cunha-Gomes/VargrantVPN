#!/bin/bash
set -eux

echo "[MONITORING] Installation de Prometheus + dépendances"

apt-get update
apt-get install -y wget tar

# Installation de Prometheus
cd /opt
wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz
tar xvf prometheus-2.52.0.linux-amd64.tar.gz
ln -s prometheus-2.52.0.linux-amd64 prometheus

# Création d'un service systemd
cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=/opt/prometheus/prometheus \
  --config.file=/opt/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/prometheus/data \
  --web.listen-address=:9090

[Install]
WantedBy=default.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now prometheus

echo "[MONITORING] Prometheus est en écoute sur le port 9090"
