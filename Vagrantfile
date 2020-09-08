# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.define "octopus-server" do |octopus_server|
    
    octopus_server.vm.hostname = "octopus-server.local"
    octopus_server.vm.network "private_network", ip: "192.168.33.10", hostname: true

    octopus_server.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "Octopus server"
      vb.cpus = 1
      vb.memory = 2048
    end

    install_docker(octopus_server)
    install_docker_compose(octopus_server)

    octopus_server.vm.provision "shell", inline: "/vagrant/scripts/octopus-server/run.sh", privileged: true
  end

  config.vm.define "octopus-worker" do |octopus_worker|
    
    octopus_worker.vm.hostname = "octopus-worker-dev01.local"
    octopus_worker.vm.network "private_network", ip: "192.168.33.11", hostname: true
    octopus_worker.vm.network "private_network", ip: "192.168.34.10", virtualbox__intnet: "kubernetes", hostname: true

    octopus_worker.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "Octopus worker dev01"
      vb.cpus = 1
      vb.memory = 512
    end

    install_k8s_tools(octopus_worker)
    octopus_worker.vm.provision "shell", inline: "/vagrant/scripts/octopus-worker/install-tentacle.sh", privileged: true
  end

  # config.vm.define "k8s-master" do |k8s_master|
    
  #   k8s_master.vm.hostname = "k8s-master.local"
  #   k8s_master.vm.network "private_network", ip: "192.168.34.20", virtualbox__intnet: "kubernetes", hostname: true

  #   k8s_master.vm.provider "virtualbox" do |vb|
  #     vb.gui = false
  #     vb.name = "k8s-master"
  #     vb.cpus = 2
  #     vb.memory = 2048
  #   end

  #   disable_swap(k8s_master)
  #   install_docker(k8s_master)
  #   install_k8s_tools(k8s_master)

  #   # echo "Init k8s cluster"
  #   # sudo kubeadm init --apiserver-advertise-address=10.0.0.20 --pod-network-cidr=192.168.0.0/16
  #   # echo "Install calico network"
  #   # curl https://docs.projectcalico.org/manifests/calico.yaml -O
  #   # kubectl apply -f calico.yaml
  # end

  # config.vm.define "k8s-worker" do |k8s_worker|
    
  #   k8s_worker.vm.hostname = "k8s-worker.local"
  #   k8s_worker.vm.network "private_network", ip: "192.168.34.21", virtualbox__intnet: "kubernetes", hostname: true

  #   k8s_worker.vm.provider "virtualbox" do |vb|
  #     vb.gui = false
  #     vb.name = "k8s-worker"
  #     vb.cpus = 1
  #     vb.memory = 2048
  #   end

  #   disable_swap(k8s_worker)
  #   install_docker(k8s_worker)
  #   install_k8s_tools(k8s_worker)
  # end
end

def install_docker(config)
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common jq
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant
    systemctl enable docker
  SHELL
end

def install_docker_compose(config)
  config.vm.provision "shell", inline: <<-SHELL
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  SHELL
end

# def install_tentacle(config)
#   config.vm.provision "shell", inline: <<-SHELL
#     apt-key adv --fetch-keys https://apt.octopus.com/public.key
#     add-apt-repository "deb https://apt.octopus.com/ stretch main"
#     apt-get update
#     apt-get -y install tentacle
#   SHELL
# end

def install_k8s_tools(config)
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update && apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >  /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
  SHELL
end

def disable_swap(config)
  config.vm.provision "shell", inline: <<-SHELL
    swapoff -a
    sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  SHELL
end

