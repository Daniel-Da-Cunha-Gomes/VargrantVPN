Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # VM clientA - réseau local du site A
  config.vm.define "clientA" do |client|
    client.vm.hostname = "clientA"
    client.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "lanA"
    client.vm.provision "shell", path: "scripts/setup_clientA.sh"
  end

  # VM siteB - routeur distant avec FRR
  config.vm.define "siteB" do |site|
    site.vm.hostname = "siteB"
    site.vm.network "private_network", ip: "192.168.1.1", virtualbox__intnet: "lanB"
    site.vm.network "private_network", ip: "10.0.0.2", virtualbox__intnet: "wan"
    site.vm.provision "shell", path: "scripts/setup_frr_siteB.sh"
  end

  # VM monitoring - pour Prometheus/Grafana
  config.vm.define "monitoring" do |mon|
    mon.vm.hostname = "monitoring"
    mon.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "lanA"
    mon.vm.provision "shell", path: "scripts/install_prometheus.sh"
  end

  # VM pfSense - NVA (manuel ou avec box spéciale)
  config.vm.define "pfsense" do |pf|
    pf.vm.box = "generic/freebsd13"  # pfSense ne fonctionne pas avec Ubuntu, il te faut une box BSD ou une image importée
    pf.vm.hostname = "pfsense"
    pf.vm.network "private_network", ip: "10.0.0.1", virtualbox__intnet: "wan"
    pf.vm.network "private_network", ip: "192.168.10.1", virtualbox__intnet: "lanA"
    pf.vm.provision "shell", inline: "echo 'Configure pfSense via GUI'"
  end
end
