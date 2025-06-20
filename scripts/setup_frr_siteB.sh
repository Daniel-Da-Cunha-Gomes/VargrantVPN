#!/bin/bash
set -eux

echo "[SITEB] Installation de FRRouting"

# Ajouter le dépôt FRR
apt-get update
apt-get install -y curl gnupg lsb-release
curl -s https://deb.frrouting.org/frr/keys.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/frr.gpg
echo "deb https://deb.frrouting.org/frr $(lsb_release -sc) frr-stable" > /etc/apt/sources.list.d/frr.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y frr frr-pythontools

echo "[SITEB] Activation des démons OSPF"
sed -i 's/bgpd=no/bgpd=no/' /etc/frr/daemons
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
systemctl restart frr

echo "[SITEB] Configuration de FRR (OSPF)"
cat <<EOF > /etc/frr/frr.conf
frr version 8.4
frr defaults traditional
hostname siteB-router
log syslog

interface eth0
 ip ospf area 0.0.0.0

interface eth1
 ip ospf area 0.0.0.0

router ospf
 ospf router-id 10.0.0.2
 network 10.0.0.0/24 area 0.0.0.0
 network 192.168.1.0/24 area 0.0.0.0

line vty
EOF

chown frr:frr /etc/frr/frr.conf
chmod 640 /etc/frr/frr.conf

systemctl restart frr

echo "[SITEB] Configuration IP statique (Netplan)"
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.1/24
    eth1:
      addresses:
        - 10.0.0.2/24
      nameservers:
        addresses: [8.8.8.8]
      routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
EOF

netplan apply
