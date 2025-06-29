Vagrant.configure("2") do |config|

  # Site A : client Linux
  config.vm.define "siteA" do |siteA|
    siteA.vm.box = "ubuntu/bionic64"
    siteA.vm.hostname = "siteA"
    siteA.vm.network "private_network", ip: "192.168.150.15"

    siteA.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y net-tools iputils-ping traceroute wireguard

      # Générer clés WireGuard
      umask 077
      wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

      # Afficher la clé publique pour copie manuelle
      echo "Clé publique siteA :"
      cat /etc/wireguard/publickey

      # Créer un fichier de config wg0.conf basique avec clé privée (à compléter après échange manuel des clés)
      PRIVATE_KEY=$(cat /etc/wireguard/privatekey)

      cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
PrivateKey = $PRIVATE_KEY
ListenPort = 51820

# [Peer]
# PublicKey = <clé_publique_siteB>
# Endpoint = <IP_siteB>:51820
# AllowedIPs = 10.0.0.0/24
# PersistentKeepalive = 25
EOF

      # Ne pas démarrer le service wg-quick@wg0 ici, config incomplète
    SHELL
  end

  # Site B : routeur Linux avec FRR (OSPF)
  config.vm.define "siteB" do |siteB|
    siteB.vm.box = "ubuntu/bionic64"
    siteB.vm.hostname = "siteB"
    siteB.vm.network "private_network", ip: "192.168.100.20", virtualbox__intnet: "intnet" # Vers pfSense LAN
    siteB.vm.network "private_network", ip: "192.168.200.1"   # Vers un autre LAN ou WAN (optionnel)

    siteB.vm.provision "shell", inline: <<-SHELL
      set -e
      
      # Installer FRR et dépendances
      apt update
      apt install -y curl gnupg2 lsb-release wireguard

      curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
      echo "deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" > /etc/apt/sources.list.d/frr.list
      apt update
      apt install -y frr frr-pythontools

      sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons
      sed -i 's/^zebra=no/zebra=yes/' /etc/frr/daemons

      systemctl enable frr
      systemctl restart frr

      # Générer clés WireGuard
      umask 077
      wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

      echo "Clé publique siteB :"
      cat /etc/wireguard/publickey

      # Créer un fichier de config wg0.conf basique avec clé privée (à compléter après échange manuel des clés)
      PRIVATE_KEY=$(cat /etc/wireguard/privatekey)

      cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $PRIVATE_KEY
ListenPort = 51820

# [Peer]
# PublicKey = <clé_publique_siteA>
# Endpoint = <IP_siteA>:51820
# AllowedIPs = 10.0.0.0/24
# PersistentKeepalive = 25
EOF

      # Configurer FRR (OSPF)
      LAN_IFACE=$(ip -o -4 addr show | grep "192.168.100.20" | awk '{print $2}')
      cat > /etc/frr/frr.conf << EOF
frr
!
hostname siteB
password zebra
enable password zebra
!
interface $LAN_IFACE
 ip address 192.168.100.20/24
!
router ospf
 router-id 2.2.2.2
 network 192.168.100.0/24 area 0
!
log file /var/log/frr/frr.log
!
EOF

      systemctl restart frr

      # Passerelle par défaut vers pfSense
      ip route del default || true
      ip route add default via 192.168.100.1 dev $LAN_IFACE
    SHELL
  end

end
