

# Déploiement d'une Infrastructure VPN + OSPF avec pfSense et Vagrant

# Objectif
Mettre en place une architecture réseau avec :

Un firewall pfSense jouant le rôle de NVA (Appliance Réseau Virtuelle)
Un VPN site-à-site (WireGuard)
Un échange de routes dynamiques via OSPF (FRRouting)
             ╔════════════════════════════╗
             ║         Site A             ║
             ║ (Client Linux)             ║
             ║                            ║
             ║ IP locale : 192.168.150.15 ║◀───────────────┐
             ╚══════╤═════════════════════╝                |
                    │                                      |
                    │ LAN                                  |
                    ▼                                      |
             ╔════════════════════════════╗                |
             ║         pfSense            ║                |
             ║ - WAN IP : 192.168.100.1   ║                |
             ║                            ║                |
             ╚══════╤═════════════════════╝                │
                    │                                      │
                    │ INTERNET ou réseau central (NAT)     │
                    ▼                                      ▼
             ╔════════════════════════════╗         ╔════════════════════════════╗
             ║         Site B             ║         ║       VPN Tunnel           ║
             ║ (Client ou Routeur)        ║◀────────▶║ 10.0.0.1 ⇄ 10.0.0.2     ║
             ║ IP locale : 192.168.100.20 ║         ╚════════════════════════════╝
             ╚════════════════════════════╝

# 1. Vagrantfile Résumé
Site A (Client)
config.vm.define "siteA" do |siteA|
  siteA.vm.box = "ubuntu/bionic64"
  siteA.vm.hostname = "siteA"
  siteA.vm.network "private_network", ip: "192.168.150.15"
  siteA.vm.provision "shell", inline: <<-SHELL
    apt update
    apt install -y wireguard net-tools iputils-ping traceroute
    umask 077
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
  SHELL
end
Site B (Routeur Linux + FRR + WireGuard)
config.vm.define "siteB" do |siteB|
  siteB.vm.box = "ubuntu/bionic64"
  siteB.vm.hostname = "siteB"
  siteB.vm.network "private_network", ip: "192.168.100.20"
  siteB.vm.network "private_network", ip: "192.168.200.1"
  siteB.vm.provision "shell", inline: <<-SHELL
    apt update
    apt install -y wireguard frr frr-pythontools curl gnupg2 lsb-release net-tools
    umask 077
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

    # Configuration FRR
    sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons
    sed -i 's/^zebra=no/zebra=yes/' /etc/frr/daemons
    systemctl enable frr && systemctl restart frr

    LAN_IFACE=$(ip -o -4 addr show | grep "192.168.100.20" | awk '{print $2}')

    cat > /etc/frr/frr.conf <<EOF
frr
!
hostname siteB
password zebra
enable password zebra
!
interface $LAN_IFACE
 ip address 192.168.100.20/24
!
interface wg0
 ip address 10.0.0.2/24
!
router ospf
 router-id 2.2.2.2
 network 192.168.100.0/24 area 0
 network 10.0.0.0/24 area 0
!
log file /var/log/frr/frr.log
!
EOF

    # Configuration passerelle
    ip route del default || true
    ip route add default via 192.168.100.1 dev $LAN_IFACE
  SHELL
end
# 2. Configuration WireGuard
Clés :
Clé publique Site A : GkIsynsjpo4QMU4fMmKuDKp3eGRxOhmHhY8FPbZJyG0=
Clé publique Site B : dteKX6fvqivRhNsqFTUFV7Tg+Hei6OFwDUyrFBu6PE4=
/etc/wireguard/wg0.conf sur Site A :
[Interface]
Address = 10.0.0.1/24
PrivateKey = <clé_privée_siteA>
ListenPort = 51820

[Peer]
PublicKey = dteKX6fvqivRhNsqFTUFV7Tg+Hei6OFwDUyrFBu6PE4=
Endpoint = 192.168.200.1:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
/etc/wireguard/wg0.conf sur Site B :
[Interface]
Address = 10.0.0.2/24
PrivateKey = <clé_privée_siteB>
ListenPort = 51820

[Peer]
PublicKey = GkIsynsjpo4QMU4fMmKuDKp3eGRxOhmHhY8FPbZJyG0=
Endpoint = 192.168.150.15:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
# 3. Tests réalisés
✅ Ping Site B ↔ Site A via VPN (10.0.0.x)
✅ Session OSPF établie entre pfSense et Site B
✅ Routes OSPF visibles
✅ VPN WireGuard actif entre les deux sites
# 4. Livrables à compléter
-

Pour toute capture ou vérification, consulter :

Status > FRR > OSPF (voisins, routes)
VPN > WireGuard (statut, tunnels)
Firewall > Rules + Logs (trafic autorisé)