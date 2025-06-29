Vagrant.configure("2") do |config|

  # Site A : client Linux
  config.vm.define "siteA" do |siteA|
    siteA.vm.box = "ubuntu/bionic64"
    siteA.vm.hostname = "siteA"
    siteA.vm.network "private_network", ip: "192.168.100.15"
    siteA.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y net-tools iputils-ping traceroute
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
      
      # 1. Ajouter dépôt FRR
      apt update
      apt install -y curl gnupg2 lsb-release
      curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
      echo "deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" > /etc/apt/sources.list.d/frr.list
      apt update

      # 2. Installer FRR
      apt install -y frr frr-pythontools

      # 3. Activer les démons OSPF dans /etc/frr/daemons
      sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons
      sed -i 's/^zebra=no/zebra=yes/' /etc/frr/daemons

      # 4. Activer et démarrer le service FRR
      systemctl enable frr
      systemctl restart frr

      # 5. Créer la config FRR si elle n'existe pas
      if [ ! -f /etc/frr/frr.conf ]; then
        touch /etc/frr/frr.conf
        chown frr:frr /etc/frr/frr.conf
        chmod 640 /etc/frr/frr.conf
      fi

      # 6. Trouver le nom exact de l'interface connectée au LAN (192.168.100.20)
      LAN_IFACE=$(ip -o -4 addr show | grep "192.168.100.20" | awk '{print $2}')
      
      # 7. Écrire la config FRR dans frr.conf
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

      # 8. Redémarrer FRR pour prendre en compte la config
      systemctl restart frr

      # 9. Configurer la passerelle par défaut vers pfSense (LAN)
      ip route del default || true
      ip route add default via 192.168.100.1 dev $LAN_IFACE
    SHELL
  end

end
