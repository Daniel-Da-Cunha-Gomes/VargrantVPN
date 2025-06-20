#!/bin/bash
set -eux

echo "[CLIENTA] Configuration réseau statique"

# Création du fichier Netplan
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.10.10/24
      gateway4: 192.168.10.1
      nameservers:
        addresses: [1.1.1.1]
EOF

netplan apply

echo "[CLIENTA] Test de connectivité"
ping -c 4 192.168.10.1 || true
